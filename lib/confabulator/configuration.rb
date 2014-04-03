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

		def initialize(thread = Libuv::Loop.default)
			@thread = thread
		end



		#use streamio to check the file and raise an error if the file is fucked
		class InvalidVideo < TypeError; end


		def check(file)
			@thread.work do
				process_video(file)
			end
		end


		protected


		S16_10 = '16:10'.freeze
		S10_16 = '10:16'.freeze
		S16_9  = '16:9'.freeze
		S9_16  = '9:16'.freeze
		S4_3   = '4:3'.freeze
		S3_4   = '3:4'.freeze


		def process_video(filename)
			video = FFMPEG::Movie.new(filename)
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

			case video.dar
			when S16_10, S10_16
				resolutions = W_16_10.select {|x| x[width] <= video.width && x[height] <= video.height}
			when S16_9, S9_16
				resolutions = W_16_9.select {|x| x[width] <= video.width && x[height] <= video.height}
			when S4_3, S3_4
				resolutions = S_4_3.select {|x| x[width] <= video.width && x[height] <= video.height}
			else
				# for non-standard resolutions we'll keep the ratios
				# and base the width off the heights of the 16:10 files
				resolutions = []
				ratio = video.__send__(width) / video.__send__(height)
				new_height = video.__send__(height)
				W_16_10.each do |x|
					if x[height] <= new_height
						new_height = x[height]
						new_width = new_height * ratio

						resolutions << {
							width => new_width,
							height => new_height
						}
					end
				end
			end

			# have a native resolution version available
			unless resolutions.length > 0 && resolutions[0][width] == video.__send__(width) && resolutions[0][height] == video.__send__(height)
				resolutions << {
					width => video.width,
					height => video.height
				}
			end

			# build a list of actions that need to be performed so the videos are in the correct format
			actions = []
			resolutions.each do |res|
				FORMATS.each do |format|
					actions << Action.new(video, res.merge(format))
				end
			end
			return actions
		end
	end
end

