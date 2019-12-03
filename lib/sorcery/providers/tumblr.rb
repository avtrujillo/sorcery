module Sorcery
  module Providers

    # aliased to avoid name collision

    class Tumblr < Base
      include Protocols::Oauth2

      def initialize
        super

        @api_site = 'https://api.tumblr.com'
        @auth_site = 'https://www.tumblr.com'
        @auth_path = "/oauth/authorize"
        @token_url = "/oauth/access_token"
        @user_info_path = "#{@api_site}/v2/blog/"
      end

      def login_url
        get_request_token.authorize_url
      end

      def access_token
        @access_token ||= get_request_token.get_access_token
      end

      def get_consumer
        ::OAuth::Consumer.new(@key, @secret, site: @auth_site, authorize_path: @auth_path)
      end

      def get_request_token
        if token && secret
          OAuth::RequestToken.new(get_consumer, token, secret)
        else
          get_consumer.get_request_token(oauth_callback: @callback_url)
        end
      end

      def get_user_hash(_access_token)
        response = access_token.get(@user_info_path)
        auth_hash(access_token).tap do |h|
          h[:user_info] = JSON.parse(response.body, symbolize_names: true)
          main_blog_name = h[:user_info][:name]
          main_blog = h[:user_info][:blogs].find{|blog| blog[:name] == main_blog_name}
          h[:uid] = main_blog[:uuid]
        end
      end

      def blog_path(blog_name, ext)
        "v2/blog/#{full_blog_name(blog_name)}/#{ext}"
      end

      def full_blog_name(blog_name)
        blog_name.include?('.') ? blog_name : "#{blog_name}.tumblr.com"
      end

      #def client(token = nil, token_secret = nil)
      #  Client.new(
      #      consumer_key: @key,
      #      consumer_secret: @secret,
      #      oauth_token: token,
      #      oauth_token_secret: token_secret
      #  )
      #end

    end
  end
end