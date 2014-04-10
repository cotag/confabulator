require 'set'

module Confabulator
	class Configuration
		
		W_16_10 = [{
				width: 1920,
				height: 1200
			},
			{
				width: 1280,
				height: 800
			},
			{
				width: 768,
				height: 480
			}]

		W_16_9 = [{
				width: 1920,
				height: 1080
			},
			{
				width: 1280,
				height: 720
			},
			{
				width: 854,
				height: 480
			}]

		S_4_3 = [{
				width: 1440,
				height: 1080
			},
			{
				width: 1024,
				height: 768
			},
			{
				width: 640,
				height: 480
			}]


		FORMATS = [
			{
				:video_codec => 'h264',  #'h264',
				:audio_codec => 'aac',
				:extension => 'mp4',
				:custom => '-strict experimental',
				:mime => 'video/mp4'
			},
			{
				#:video_codec => 'vp8', #'vp8',
				#:audio_codec => 'vorbis',  #'vorbis',
				:extension => 'webm',
				:custom => '-strict experimental',
				:mime => 'video/webm'
			}
		]

		def initialize(file)
			@file = file
			process_video(@file)
		end


		attr_reader :file    # the filename
        attr_reader :video   # the ffmpeg wrapper
        attr_reader :actions # the actions required for conversion


		#use streamio to check the file and raise an error if the file is fucked
		class InvalidVideo < TypeError; end


		protected


		S16_10 = 10.0 / 16.0
		S16_9  = 9.0 / 16.0
		S4_3   = 3.0 / 4.0


		def process_video(filename)
			@video = FFMPEG::Movie.new(filename)
			raise InvalidVideo unless video.valid?
			raise InvalidVideo if video.video_codec.nil?
			return generate_actions(video)
		end

		def generate_actions(video)
			# Check for portrait videos vs the regular landscape
			portrait = video.width < video.height

			if portrait
				width = :height
				height = :width
			else
				width = :width
				height = :height
			end

			resolutions = []
			list = nil
			ratio = video.__send__(height).to_f / video.__send__(width).to_f

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
				new_width = video.__send__(width)
				W_16_10.each do |x|
					if x[width] <= new_width
						new_width = x[width]
						new_height = (new_width * ratio).round

						resolutions << {
							:width => new_width,
							:height => new_height
						}
					end
				end
			else
				# Standard resolution
				list.each do |res|
					if res[width] <= video.width && res[height] <= video.height
						resolutions << {
							:width => res[width],
							:height => res[height]
						}
					end
				end
			end

			# have a native resolution version available
			unless resolutions.length > 0 && resolutions[0][:width] == video.width && resolutions[0][:height] == video.height
				resolutions << {
					:width => video.width,
					:height => video.height
				}
			end

			# build a list of actions that need to be performed so the videos are in the correct format
			actions = []
			time = (video.duration * 0.3).to_i

			resolutions.each do |res|
				actions << Action.new(video, res.merge({
					poster: time
				}))
				
				FORMATS.each do |format|
					actions << Action.new(video, res.merge(format))
				end
			end
			@actions = actions
		end
	end
end

