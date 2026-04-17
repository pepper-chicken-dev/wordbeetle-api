# Safelists
Rack::Attack.safelist('allow-health-check') do |req|
  req.path == '/up' && req.get?
end

# Throttles
Rack::Attack.throttle('auth/guest', limit: 5, period: 1.minute) do |req|
  req.ip if req.path == '/api/v1/auth/guest' && req.post?
end

Rack::Attack.throttle('auth/google', limit: 5, period: 1.minute) do |req|
  req.ip if req.path == '/api/v1/auth/google' && req.post?
end

Rack::Attack.throttle('api/ip', limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?('/api/')
end

# Custom JSON response for throttled requests
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data']
  now = match_data[:epoch_time]
  retry_after = match_data[:period] - (now % match_data[:period])

  [
    429,
    {
      'Content-Type' => 'application/json; charset=utf-8',
      'Retry-After' => retry_after.to_s
    },
    [{ error: "Rate limit exceeded. Retry after #{retry_after} seconds." }.to_json]
  ]
end
