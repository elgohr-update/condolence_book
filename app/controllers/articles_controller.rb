class ArticlesController < ApplicationController

  def new
    render 'articles/new'
  end

  def create
    @article = Article.new(article_params)
    if @article.save
      email_confirmation(@article)
      flash[:success] = "Bitte bestätige deine E-Mail Adresse bevor wir den Post veröffentlichen können."
      redirect_to root_url
    else
      flash[:error] = "Es ist ein Fehler aufgetreten, bitte versuche es erneut."
    end
  end

  def show
    @article = Article.find(params[:id])
    render 'articles/show'
  end

  def confirm_email
    article = Article.find_by_confirm_token(params[:id])
    if article
      if article.email_activate!
        post_publish(article)
        flash[:success] = "Vielen Dank! Deine E-Mail Adresse wurde bestätigt. \nWir überprüfen deinen Post und veröffentlichen ihn dann."
        redirect_to root_url
      end
    else
      flash[:error] = "Dieses Token ist nicht gültig."
      redirect_to root_url
    end
  end

  def publish_post
    article = Article.find_by_publish_token(params[:id])
    if article
      article.publish!
      flash[:success] = "Vielen Dank! Der Post wurde veröffentlicht."
      redirect_to article
    else
      flash[:error] = "Dieses Token ist nicht gültig."
      redirect_to root_url
    end
  end

  private

  def email_confirmation(article)
    api_key = ENV['mailgun_api_key']
    domain = ENV['mailgun_email_domain']

    @article = article
    html_output = render_to_string template: 'user_mailer/email_confirmation.text'

    response = RestClient.post "https://api:#{api_key}"\
        "@api.mailgun.net/v3/#{domain}/messages",
                               :from => "Kondolenzbuch Pascal <info@#{domain}>",
                               :to => "<#{article.email}>",
                               :subject => 'Email Bestätigung',
                               :text => html_output.to_str

    JSON.parse(response)
  end

  def post_publish(article)
    api_key = ENV['mailgun_api_key']
    domain = ENV['mailgun_email_domain']
    confirmation_email = ENV['post_publish_email']

    @article = article
    html_output = render_to_string template: 'user_mailer/email_publication.text'

    response = RestClient.post "https://api:#{api_key}"\
        "@api.mailgun.net/v3/#{domain}/messages",
                               :from => "Kondolenzbuch Pascal <info@#{domain}>",
                               :to => "<#{confirmation_email}>",
                               :subject => 'Post Bestätigung',
                               :text => html_output.to_str

    JSON.parse(response)
  end

  def article_params
    params.require(:article).permit(:title, :text, :tag, :email)
  end
end
