
module Confabulator
	class Configuration
		
		W_16_10 = [{
				width: 1920,
				height: 1200,

			},
			{
				width: 1280,
				height: 800
			},
			{
				width: 768
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
				width: 854
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

		STR_16_10 = '16:10'.freeze
		STR_16_9 = '16:9'.freeze
		STR_4_3 = '4:3'.freeze



		#NON_STANDARD = []
		# ratio = width / height
		# new_h = W_16_10[closest match].height
		# width = new_h * ratio


		FORMATS = [
			{
				:vcodec => 'h264',
				:acodec => 'aac',
				:extension => 'mp4'
			},
			{
				:vcodec => 'vp8',
				:acodec => 'vorbis',
				:extension => 'webm'
			}
		]

		def initialize(thread = Libuv::Loop.default)
			@thread = thread
		end



		#use streamio to check the file and raise an error if the file is fucked
		class InvalidVideo < TypeError; end

		def process_video(filename)
			video = FFMPEG::Movie.new(filename)
			raise InvalidVideo unless video.valid?
			raise InvalidVideo if video.video_codec.nil?
			return generate_actions(video)
		end

		def generate_actions(video)
			case video.dar
			when STR_16_10
				resolutions = W_16_10.filter {|x| x[:width] <= video.width && x[:height] <= video.height}
			when STR_16_9
				resolutions = W_16_9.filter {|x| x[:width] <= video.width && x[:height] <= video.height}
			when STR_4_3
				resolutions = W_4_3.filter {|x| x[:width] <= video.width && x[:height] <= video.height}
			else
				resolutions = []
				ratio = video.width / video.height
				new_height = video.height
				W_16_10.each do |x|
					if x[:height] <= new_height
						new_height = x[:height]
						width = new_height * ratio

						resolutions << {
							width: width,
							height: new_height
						}
					end
				end
			end

			# native
			unless resolutions.length > 0 && resolutions[0].width == video.width && resolutions[0].height == video.height
				resolutions << {
					width: video.width,
					height: video.height
				}
			end

			actions = []
			resolutions.each do |res|
				FORMATS.each do |format|
					action = Action.new(video, res.merge(format))
				end
			end
			return actions
		end


		def transcode(file)
			@thread.work do
				process_video(file)
			end
		end
	end
end

