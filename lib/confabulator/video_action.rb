
module Confabulator
    class VideoAction
    	

    	def initialize(video, options)
            @options = options
            @resolution = "#{options[:width]}x#{options[:height]}"
            @options[:resolution] = @resolution  # add the conversion resolution to the options
            @video = video

            path = File.dirname(video.path.gsub("\\", "/"))
            name = File.basename(video.path.gsub("\\", "/"), '.*')
            
            @complete = false

            @poster = !!@options[:poster]
            if is_poster?
                @outputname = "#{File.join(path, name)}_#{@resolution}.jpg"
                @options[:mime] = 'image/jpeg'
            else
                @outputname = "#{File.join(path, name)}_#{@resolution}.#{options[:extension]}"
            end
        end


        attr_accessor :store

        attr_reader :complete    # Has been transcoded?
        attr_reader :outputname  # filename
        attr_reader :resolution  # resolution
        attr_reader :options     # mime
        

        def is_poster?
            @poster
        end

    	def transcode
            if @poster
                @video.screenshot(@outputname, seek_time: @options[:poster], resolution: @resolution)
            else
                @video.transcode(@outputname, @options, { validate: false }) do |progress|
                    #method called with progress
                    yield progress if block_given?
                end
                @complete = true
            end
    	end
    end
end
