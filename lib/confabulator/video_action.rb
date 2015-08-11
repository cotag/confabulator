
module Confabulator
    class VideoAction
    	

    	def initialize(video, options)
            @options = options
            @resolution = "#{options[:width]}x#{options[:height]}"
            @options[:resolution] = @resolution  # add the conversion resolution to the options
            @video = video

            @skip_transcode = false

            path = File.dirname(video.path.gsub("\\", "/"))
            name = File.basename(video.path.gsub("\\", "/"), '.*')
            
            @complete = false

            @poster = !!@options[:poster]
            if is_poster?
                @outputname = "#{File.join(path, name)}_#{@resolution}.jpg"
                @options[:mime] = 'image/jpeg'
                return
            end

            # Skip transcoding if there is a rough format and size match
            if options[:fast]
                skip = true

                if (options[:width] && options[:width] != video.width) ||
                    (options[:height] && options[:height] != video.height)
                    skip = false
                else
                    if options[:formats] && options[:formats].include?('mp4')
                        skip = video.video_codec =~ /h264/i && video.audio_codec =~ /aac/i
                    end

                    if skip && options[:formats] && options[:formats].include?('webm')
                        skip = video.video_codec =~ /h264/i && video.audio_codec =~ /aac/i
                    end
                end

                @outputname = video.path
                @skip_transcode = skip
                return
            end

            @outputname = "#{File.join(path, name)}_#{@resolution}.#{options[:extension]}"
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
                unless @skip_transcode
                    @video.transcode(@outputname, @options, { validate: false }) do |progress|
                        #method called with progress
                        yield progress if block_given?
                    end
                end
                @complete = true
            end
    	end
    end
end
