require 'set'

module Confabulator
    class Configuration
        PROFILE_HIGH = 'high'.freeze

        
        W_16_10 = [
            {   # 8K
                width: 7680,
                height: 4800,
                video_bitrate: 7500,
                audio_bitrate: 192
            },
            {   # 4K
                width: 3840,
                height: 2400,
                video_bitrate: 4000,
                audio_bitrate: 192
            },
            {
                width: 1920,
                height: 1200,
                video_bitrate: 3500,
                audio_bitrate: 192,
                x264_vprofile: PROFILE_HIGH
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

        W_16_9 = [
            {   # 8K
                width: 7680,
                height: 4320,
                video_bitrate: 7000,
                audio_bitrate: 192
            },
            {   # 4K
                width: 3840,
                height: 2160,
                video_bitrate: 3500,
                audio_bitrate: 192
            },
            {   # 1080p
                width: 1920,
                height: 1080,
                video_bitrate: 3000,
                audio_bitrate: 192,
                x264_vprofile: PROFILE_HIGH
            },
            {   # 720p
                width: 1280,
                height: 720,
                video_bitrate: 2000,
                audio_bitrate: 128
            },
            {   # 480p
                width: 854,
                height: 480,
                video_bitrate: 900,
                audio_bitrate: 128
            }]

        S_4_3 = [
            {
                width: 6400,
                height: 4800,
                video_bitrate: 6500,
                audio_bitrate: 192
            },
            {
                width: 3200,
                height: 2400,
                video_bitrate: 4000,
                audio_bitrate: 192
            },
            {
                width: 1440,
                height: 1080,
                video_bitrate: 3000,
                audio_bitrate: 192,
                x264_vprofile: PROFILE_HIGH
            },
            {
                width: 960,
                height: 720,
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
        S4_3   = 3.0 / 4.0     # / # -- Ruby code editors seem to struggle with division

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

                        # Heights must be divisible by 2
                        new_height = new_height - (new_height % 2)

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
                    :height => objHeight,
                    :x264_vprofile => PROFILE_HIGH,
                    :audio_bitrate => 192
                }
            end

            resolutions
        end


        def initialize(file, type, options = {})
            @filename = file
            @options = ActiveSupport::HashWithIndifferentAccess.new.deep_merge(options)
            # Options:
            # * native_only: only have a single copy of the video
            # * formats: [array of whitelisted file extensions]
            # * fast: if resoltion and codecs are correct then don't transcode
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
                :extension => 'mp4',
                :custom => '-strict experimental -pix_fmt yuv420p',
                :mime => 'video/mp4',
                :autorotate => true,
                :x264_vprofile => 'baseline',
                :threads => 2
            },
            {
                :extension => 'webm',
                # good + 0 == best quality just faster, crf 8, min 0 max 40 == good quality
                :custom => '-strict experimental -quality good -cpu-used 1 -crf 10 -qmin 0 -qmax 40 -pix_fmt yuv420p',
                :mime => 'video/webm',
                :autorotate => true,
                :threads => 2,
                :remove => [:x264_vprofile] # ensure this option is not included for webm
            }
        ]

        def video_actions(video)
            # Check if multiple resolutions are desirable
            resolutions = []
            if @options[:native_only]
                resolutions << {
                    :width => video.width,
                    :height => video.height,
                    :x264_vprofile => PROFILE_HIGH,
                    :audio_bitrate => 192
                }
            else
                resolutions = Configuration.calculate_sizes(video.width, video.height)
            end

            # build a list of actions that need to be performed so the videos are in the correct format
            actions = []
            time = (video.duration * 0.3).to_i

            resolutions.each do |res|
                actions << VideoAction.new(video, res.merge({
                    poster: time
                }))
                
                VIDEO_FORMATS.each do |format|
                    next if @options[:formats] && !@options[:formats].include?(format[:extension])
                    opts = ActiveSupport::HashWithIndifferentAccess.new.deep_merge(format.merge(res))

                    # Upgrade encoding to h265
=begin
the web is not ready for this
                    if opts[:width] > 1920 || opts[:height] > 1200
                        if opts[:video_codec] == 'h264'
                            opts[:video_codec] = 'libx265'
                            remove = opts[:remove] || []
                            remove << :x264_vprofile
                            opts[:remove] = remove
                            opts[:custom] = "#{opts[:custom]} -preset medium"
                        elsif opts[:video_codec] == 'libvpx'
                            # WARN:: this codec takes hours to encode a 20second video
                            opts[:video_codec] = 'libvpx-vp9'
                        end
                    end
=end

                    opts[:remove].each { |key| opts.delete(key) } if opts[:remove]

                    # clamp audio bitrate between 24k and opts[:audio_bitrate]
                    if opts[:audio_bitrate]
                        opts[:audio_bitrate] = [[opts[:audio_bitrate], video.audio_bitrate / 1000].min, 24].max
                    end
                    # / # Editor fix
                    
                    # Ensure there are a fixed number of frames for a standard GOP size
                    # This allows us to support DASH
                    frame_rate = video.frame_rate.ceil
                    opts[:frame_rate] = frame_rate
                    opts[:keyframe_interval] = frame_rate * 2
                    
                    actions << VideoAction.new(video, opts.merge(@options))
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

