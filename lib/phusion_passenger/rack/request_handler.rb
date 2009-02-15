#  Phusion Passenger - http://www.modrails.com/
#  Copyright (c) 2008, 2009 Phusion
#
#  "Phusion Passenger" is a trademark of Hongli Lai & Ninh Bui.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

require 'phusion_passenger/abstract_request_handler'
module PhusionPassenger
module Rack

# A request handler for Rack applications.
class RequestHandler < AbstractRequestHandler
	# Constants which exist to relieve Ruby's garbage collector.
	RACK_VERSION       = "rack.version"        # :nodoc:
	RACK_VERSION_VALUE = [0, 1]                # :nodoc:
	RACK_INPUT         = "rack.input"          # :nodoc:
	RACK_ERRORS        = "rack.errors"         # :nodoc:
	RACK_MULTITHREAD   = "rack.multithread"    # :nodoc:
	RACK_MULTIPROCESS  = "rack.multiprocess"   # :nodoc:
	RACK_RUN_ONCE      = "rack.run_once"       # :nodoc:
	RACK_URL_SCHEME	   = "rack.url_scheme"     # :nodoc:
	SCRIPT_NAME        = "SCRIPT_NAME"         # :nodoc:
	PATH_INFO          = "PATH_INFO"           # :nodoc:
	HTTPS          = "HTTPS"  # :nodoc:
	HTTPS_DOWNCASE = "https"  # :nodoc:
	HTTP           = "http"   # :nodoc:
	YES            = "yes"    # :nodoc:
	ON             = "on"     # :nodoc:
	ONE            = "one"    # :nodoc:
	CRLF           = "\r\n"   # :nodoc:

	# +app+ is the Rack application object.
	def initialize(owner_pipe, app, options = {})
		super(owner_pipe, options)
		@app = app
	end

protected
	# Overrided method.
	def process_request(env, input, output)
		env[RACK_VERSION]      = RACK_VERSION_VALUE
		env[RACK_INPUT]        = input
		env[RACK_ERRORS]       = STDERR
		env[RACK_MULTITHREAD]  = false
		env[RACK_MULTIPROCESS] = true
		env[RACK_RUN_ONCE]     = false
		env[SCRIPT_NAME]     ||= ''
		if ENV.has_key?(PATH_INFO)
			env[PATH_INFO].sub!(/^#{Regexp.escape(env[SCRIPT_NAME])}/, "")
		end
		if env[HTTPS] == YES || env[HTTPS] == ON || env[HTTPS] == ONE
			env[RACK_URL_SCHEME] = HTTPS_DOWNCASE
		else
			env[RACK_URL_SCHEME] = HTTP
		end
		
		status, headers, body = @app.call(env)
		begin
			output.write("Status: #{status}#{CRLF}")
			headers[X_POWERED_BY] = PASSENGER_HEADER
			headers.each_pair do |k, v|
				output.write("#{k}: #{v}#{CRLF}")
			end
			output.write(CRLF)
			if body.is_a?(String)
				output.write(body)
			elsif body
				body.each do |s|
					output.write(s)
				end
			end
		ensure
			body.close if body.respond_to?(:close)
		end
	end
end

end # module Rack
end # module PhusionPassenger
