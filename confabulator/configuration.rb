class Configuration
	
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

	def initialize
		@thread = Libuv::Loop.default

		#exists = @thread.work method(:perform_check)
	end



	#use streamio to check the file and raise an error if the file is fucked

	def process_video(filename)
		video = FFMPEG::Movie.new(filename)
		raise InvalidVideo if not video.valid?
		raise InvalidVideo if video.video_codec.nil?
		#handle aspect ratio
		@actions = generate_actions(video)
		return @actions
	end

	def generate_actions(video)

		#1.7 for 16:9 or 1.3 for 4:3
		if video.width > 1920 && video.height > 1080
			#generate NATIVE, 1080p, 720p, 480p, HLS and DASH

		elsif video.width == 1920 && video.height == 1080
			#generate 1080p, 720p, 480p, HLS and DASH

		elsif video.width > 1280 && video.height > 720
			#generate NATIVE, 720p, 480p, HLS and DASH

		elsif video.width == 1280 && video.height == 720
			#generate 720p, 480p, HLS and DASH

		elsif video.width < 1280 && video.height < 720
			#NATIVE, HLS and DASH

		end
		return @actions
	end


	def transcode(file)
		exists = @thread.work do 
			process_video(file)
		end
		exists.catch do |error| 
			puts "Sorry there was an #{error}"
		end

		exists.then do |result|

		end
		
	end



end