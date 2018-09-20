
library utils.api_response;

/// A response to be used in all RPC communications
class ApiResponse {
  String result;
  ApiResponse();
  String toString() => result;
}

