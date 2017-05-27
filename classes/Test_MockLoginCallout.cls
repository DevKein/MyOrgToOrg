@isTest
global class Test_MockLoginCallout implements HttpCalloutMock {

	protected Integer code;
	protected String status;
	protected String body;
	protected Map<String, String> responseHeaders;
	/**
	 * Mock Http request
	 * @param  code            request code
	 * @param  status          request status
	 * @param  body            request body
	 * @param  responseHeaders request headers
	 * @return                 N/A
	 * @see  HttpCalloutMock
	 */
	global Test_MockLoginCallout(Integer code, String status, String body, Map<String, String> responseHeaders) {
		this.code = code;
		this.status = status;
		this.body = body;
		this.responseHeaders = responseHeaders;
	}
	/**
	 * Mock response
	 * @param  req Http request
	 * @return     HttpResponse
	 * @see  HttpResponse
	 */
	global HTTPResponse respond(HTTPRequest req) {
		HttpResponse res = new HttpResponse();
		for (String key : this.responseHeaders.keySet()) {
			res.setHeader(key, this.responseHeaders.get(key));
		}
		res.setBody(this.body);
		res.setStatusCode(this.code);
		res.setStatus(this.status);
		return res;
	}
}