import 'dart:async';
import 'dart:io' show HandshakeException, SocketException;

import 'package:http/http.dart' as http;

/// True only for real transport failures (no answer from the server).
///
/// Anything else is a server answer or a bug, and must not be shown to the
/// user as "no internet".
bool isNetworkError(Object error) =>
    error is SocketException ||
    error is HandshakeException ||
    error is TimeoutException ||
    error is http.ClientException;
