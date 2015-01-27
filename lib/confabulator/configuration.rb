require 'set'

module Confabulator
	class Configuration
		
		W_16_10 = [{
				width: 1920,
				height: 1200,
				video_bitrate: 3500,
				audio_bitrate: 192,
				x264_vprofile: 'high'
			},
			{
				width: 1280,
				height: 800,
				video_bitrate: 2000,
				audio_bitrate: 128
			},
			{
				width: 768,
				height: 480,
				video_bitrate: 850,
				audio_bitrate: 128
			}]

		W_16_9 = [{
				width: 1920,
				height: 1080,
				video_bitrate: 3000,
				audio_bitrate: 192,
				x264_vprofile: 'high'
			},
			{
				width: 1280,
				height: 720,
				video_bitrate: 2000,
				audio_bitrate: 128
			},
			{
				width: 854,
				height: 480,
				video_bitrate: 900,
				audio_bitrate: 128
			}]

		S_4_3 = [{
				width: 1440,
				height: 1080,
				video_bitrate: 3000,
				audio_bitrate: 192,
				x264_vprofile: 'high'
			},
			{
				width: 1024,
				height: 768,
				video_bitrate: 2000,
				audio_bitrate: 128
			},
			{
				width: 640,
				height: 480,
				video_bitrate: 800,
				audio_bitrate: 128
			}]

		S16_10 = 10.0 / 16.0
		S16_9  = 9.0 / 16.0
		S4_3   = 3.0 / 4.0

		def self.calculate_sizes(objWidth, objHeight)
			# Check for portrait videos vs the regular landscape
			portrait = objWidth < objHeight

			if portrait
				width = :height
				height = :width
				ratio = objWidth.to_f / objHeight.to_f
				new_width = objHeight
			else
				width = :width
				height = :height
				ratio = objHeight.to_f / objWidth.to_f
				new_width = objWidth
			end

			resolutions = []
			list = nil

			case ratio
			when S16_10
				list = W_16_10
			when S16_9
				#resolutions = W_16_9.select {|x| x[width] <= video.width && x[height] <= video.height}
				list = W_16_9
			when S4_3
				#resolutions = S_4_3.select {|x| x[width] <= video.width && x[height] <= video.height}
				list = S_4_3
			end

			# Compile a list of resolutions we want to build
			if list.nil?
				# non-standard resolution
				# keep the ratios and base the width off the heights of the 16:10 files
				W_16_10.each do |x|
					if x[:width] <= new_width
						new_width = x[width]
						new_height = (new_width * ratio).round

						resolutions << x.merge({
							:width => new_width,
							:height => new_height
						})
					end
				end
			else
				# Standard resolution
				list.each do |res|
					if res[:width] <= new_width
						resolutions << res.merge({
							:width => res[width],
							:height => res[height]
						})
					end
				end
			end

			# have a native resolution version available
			if resolutions.length == 0 || !(resolutions[0][:width] == objWidth && resolutions[0][:height] == objHeight)
				resolutions << {
					:width => objWidth,
					:height => objHeight
				}
			end

			resolutions
		end


		def initialize(file, type)
			@filename = file
			self.__send__ :"process_#{type}"
		end


		attr_reader :filename
		attr_reader :meta    # the ffmpeg / magick wrapper
		attr_reader :actions # the actions required for conversion


		#use streamio to check the file and raise an error if the file is bad
		class InvalidImage < TypeError; end
		class InvalidVideo < TypeError; end


		protected


		def process_video
			@meta = FFMPEG::Movie.new(filename)
			raise InvalidVideo unless meta.valid?
			raise InvalidVideo if meta.video_codec.nil?
			video_actions(meta)
		end

		def process_image
			@meta = Magick::Image.new(filename)
			raise InvalidImage unless meta.valid?
			image_actions(meta)
		end


		VIDEO_FORMATS = [
			{
				:video_codec => 'h264',  #'h264',
				:audio_codec => 'aac',
				:extension => 'mp4',
				:custom => '-strict experimental',
				:mime => 'video/mp4',
				:autorotate => true,
				:x264_vprofile => 'baseline'
			},
			{
				#:video_codec => 'vp8', #'vp8',
				#:audio_codec => 'vorbis',  #'vorbis',
				:extension => 'webm',
				# good + 0 == best quality just faster, crf 4, min 0 max 40 == good quality
				:custom => '-strict experimental -quality good -cpu-used 0 -threads 4 -crf 4 -qmin 0 -qmax 40',
				:mime => 'video/webm',
				:autorotate => true,
				:remove => [:x264_vprofile] # ensure this option is not included for webm
			}
		]

		def video_actions(video)
			resolutions = Configuration.calculate_sizes(video.width, video.height)

			# build a list of actions that need to be performed so the videos are in the correct format
			actions = []
			time = (video.duration * 0.3).to_i

			resolutions.each do |res|
				actions << VideoAction.new(video, res.merge({
					poster: time
				}))
				
				VIDEO_FORMATS.each do |format|
					opts = format.merge(res)
					format[:remove].each { |key| opts.delete(key) } if format[:remove]

					# clamp audio bitrate between 24k and opts[:audio_bitrate]
					if opts[:audio_bitrate]
						opts[:audio_bitrate] = [[opts[:audio_bitrate], video.audio_bitrate / 1000].min, 24].max
					end
					actions << VideoAction.new(video, opts)
				end
			end
			@actions = actions
		end


		IMAGE_FORMATS = Set.new(['PNG', 'JPEG', 'GIF'])

		def image_actions(image)
			resolutions = Configuration.calculate_sizes(image.width, image.height)

			# build a list of actions that need to be performed so the videos are in the correct format
			actions = []

			# Do we need to change format?
			if IMAGE_FORMATS.include? image.codec
				ext = image.codec.downcase
				options = {
					mime: "image/#{ext}",
					extension: ext
				}
			else
				# We'll always use a lossless format
				options = {
					mime: 'image/png',
					extension: 'png'
				}
			end

			# Create an image for each resolution
			resolutions.each do |res|
				actions << ImageAction.new(image, res.merge(options.merge({
					poster: true
				})))
			end

			# store original version, potentially in a different format to the original
			actions << ImageAction.new(image, options.merge({
				width: image.width,
				height: image.height,
				poster: false
			}))

			@actions = actions
		end
	end
end

