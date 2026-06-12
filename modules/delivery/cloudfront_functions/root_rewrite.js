function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri === '/') {
        request.uri = '/index.html';
        return request;
    }

    if (uri.includes('.')) {
        return request;
    }

    request.uri = '/index.html';
    return request;
}
