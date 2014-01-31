
module Confabulator
    class Action
    	

    	def initialize(video, options)
            @options = options
            @resolution = "#{options[:width]}x#{options[:height]}"
            @video = video
            @outputname = "#{video.filename}_#{@resolution}.#{options[:extension]}"
        end


    #resolution
    #filename
    #remux or re-encode
    #output filename

    	


    	def transcode(thread)
            @thread = thread
            @worker = @thread.defer

            @worker.resolve(@thread.work(method(:do_work)))

            @worker.promise
    	end


        protected

        def do_work
            @video.transcode(@outputname, @options) do |progress|
                #method called with progress
                @thread.schedule do
                    @worker.notify progress
                end
            end
        end
    end
end
