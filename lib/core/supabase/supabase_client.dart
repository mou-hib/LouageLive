import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Initialises Supabase. Must be called once, before `runApp`.
Future<void> initSupabase() => Supabase.initialize(
  url: Env.supabaseUrl,
  // Accepts the legacy anon key or the new publishable key (both public).
  publishableKey: Env.supabaseAnonKey,
);

/// The Supabase client, injectable (and overridable in tests).
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
