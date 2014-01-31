
module Confabulator
    class Action
    	

    	def initialize(video, options)
            @options = options
            @movie = movie
        end


    #resolution
    #filename
    #remux or re-encode
    #output filename

    	


    	def transcode(thread)
            thread.work method(:do_work)
    	end


        protected

        def do_work

        end
    end
end
