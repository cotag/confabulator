class Configuration
	
	WIDESCREEN = [{
			width: 1920,
			height: 1080
		},
		{
			width: 1280,
			height: 720
		},
		{
			width: 480,
			height: 320
		}]

	STANDARD = [{
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
		},
		{
			width: 480,
			height: 320
		}]

	#NON_STANDARD = []

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


		# aspect_ratio = video.width / video.height
		# if aspect_ratio > 1.7
		# 	#widescreen
		# else
		# 	#normal
		# end

		if video.dar == "16:9" || video.dar == "16:10"
			resolutions = WIDESCREEN.filter {|x| x[:width] <= video.width && x[:height] <= video.height}

		else
			resolutions = STANDARD.filter {|x| x[:width] <= video.width && x[:height] <= video.height}
		end
		resolutions.each do |res|
			#generate the action for the resolution
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
		#result is an array of actions
		exists.then do |result|

		end
		
	end



end