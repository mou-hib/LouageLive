import 'dart:async';
import 'dart:io' show HandshakeException, SocketException;

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthRetryableFetchException;

/// True only for real transport failures (no answer from the server).
///
/// Anything else is a server answer or a bug, and must not be shown to the
/// user as "no internet".
bool isNetworkError(Object error) =>
    error is SocketException ||
    error is HandshakeException ||
    error is TimeoutException ||
    error is http.ClientException;

/// [isNetworkError], plus gotrue's wrapper: Supabase Auth turns transport
/// failures into an [AuthRetryableFetchException] without a status code.
/// With a status code (5xx) it is a server error, not a network one.
bool isAuthNetworkError(Object error) =>
    isNetworkError(error) ||
    (error is AuthRetryableFetchException && error.statusCode == null);
