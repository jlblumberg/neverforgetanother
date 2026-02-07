# Resend API key. Get it from https://resend.com/api-keys
# Set RESEND_API_KEY in .env (development) or your production env.
if ENV["RESEND_API_KEY"].present?
  Resend.api_key = ENV["RESEND_API_KEY"]
end
