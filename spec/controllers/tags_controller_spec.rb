require 'rails_helper'


describe TagsController do
  render_views

  before do
    activate_authlogic
    @gml = FactoryBot.build(:gml_object).data
    allow_any_instance_of(GmlObject).to receive(:data).and_return(DEFAULT_GML)
  end

  describe "POST #create" do
    it "routes from POST /tags"
    it "routes from POST /data"

    it "should create given params[:gml]" do
      post :create, gml: @gml
      assigns[:tag].should be_valid
      response.should be_success
      response.body.should match(/\d+/)
    end

    it "should fail without params[:gml]" do
      post :create
      response.status.should == 422 # Unprocessible Entity
      response.body.should match(/Error/)
    end

    it "should create and assign to tempt1 given the correct secret" do
      skip 'TODO'
      @tag = FactoryBot.create(:tag_from_tempt1)
      # ...
    end

    describe "redirection" do
      it "params[:redirect]=1 should redirect to the tag page" do
        Tag.destroy_all # FIXME not sure why we're ending up w/ dupe objs??
        post :create, gml: @gml, redirect: 1
        assigns[:tag].should be_valid
        response.should redirect_to(tag_path(assigns[:tag]))
      end

      it "params[:redirect_to]='http://google.com' should redirect there" do
        url = "http://google.com"
        post :create, gml: @gml, redirect_to: url
        response.should redirect_to(url)
      end

      it "params[:redirect_back]=1 should redirect to the HTTP_REFERER" do
        request.env['HTTP_REFERER'] = "http://fffff.at"
        post :create, gml: @gml, redirect_back: 1
        response.should redirect_to("http://fffff.at")
      end

    end

    describe "cache expiry" do
      it "should expire Home#index.html" do
        pending "TODO"
        fail
        route = {controller: 'home', method: 'index'}
        # lambda { post :create, gml: @gml }.should expire_fragment(route)
      end

      it "should expire Tags#index, all formats" do
        pending "TODO"
        fail
      end

      it "should expire Tags#show, all formats" do
        pending "TODO"
        fail
      end
    end
  end

  describe "GET #index" do
    before do
      @default_tag = FactoryBot.create(:tag)
      @should_mention_application = lambda { |matchable|
        response.should be_success
        response.body.should match(matchable)
        # We're listing apps in a menu on the page so this always fails! d'oh!
        # response.body.should_not match(@default_tag.application)
      }
    end

    it "should work" do
      get :index
      response.should be_success
      response.body.should match(/'application'/)
    end

    it "should not raise exception if invalid ?page= param is passed" do
      get :index, page: "-3242' UNION ALL SELECT 70,70,70,70#"
      flash[:error].should match(/Invalid page number/)
      response.should redirect_to(tags_path)
    end

    it "should filter on keywords" do
      FactoryBot.create(:tag, application: 'mfcc_test_app', gml_keywords: 'mfcc')
      get :index, keywords: 'mfcc'
      @should_mention_application.call(/mfcc_test_app/)
    end

    it "should filter on location" do
      FactoryBot.create(:tag, application: 'location_test', location: 'San Francisco')
      get :index, location: 'San Francisco'
      @should_mention_application.call(/location_test/)
    end

    it "should filter on application (using 'application')" do
      FactoryBot.create(:tag, application: 'app_test')
      get :index, application: 'mfcc'
      # @should_mention_application.call(/app_test/)
    end

    it "should filter on application (using 'gml_application')" do
      FactoryBot.create(:tag, application: 'displayed_name', gml_application: 'real_test_string')
      get :index, application: 'real_test_string'
      # @should_mention_application.call(/displayed_name/)
    end

    it "should filter on user (using last 5 characters of gml_uniquekey_hash)" do
      tag = FactoryBot.create(:tag, application: 'user_test', gml_uniquekey: 'lol')
      get :index, user: tag.secret_username # TODO rename this method, it is undescriptive
      # @should_mention_application.call(/user_test/)
    end

    it "should work for a valid user" do
      user = FactoryBot.create(:user)
      get :index, user_id: user.login
      assigns(:user).should == user
      response.should be_success
    end

    it "should 404 for a missing user" do
      lambda {
        get :index, user_id: 'asfdasadfasdf'
        assigns(:user).should be_blank
      }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #show" do
    before do
      @tag = FactoryBot.create(:tag,
        description: "An <b>html</b> description which might contain XSS!",
        location: "http://locationURL.com",
        gml_application: "Some Application name",
        gml_keywords: "some,gml,keywords")
    end

    it ".html (default)" do
      get :show, id: @tag.to_param
      response.should be_success
      response.body.should match(/Tag ##{@tag.id}/)
    end

    it ".gml" do
      get :show, id: @tag.to_param, format: 'gml'
      response.should be_success
      response.body.should match("<gml><tag><header>")
    end

    it ".xml" do
      get :show, id: @tag.to_param, format: 'xml'
      response.should be_success
      response.body.should match("<id>")
    end

    describe ".json" do
      it "should work" do
        get :show, id: @tag.to_param, format: 'json'
        response.should be_success
        response.body.should match("\"id\":#{@tag.id}")
      end

      it "should include GML data (GSON)" do
        get :show, id: @tag.to_param, format: 'json'
        response.body.should match("\"gml\":")
      end
    end

    it ".gml should fail gracefully if GML data file is missing" do
      tag = FactoryBot.create(:tag)
      allow_any_instance_of(Tag).to receive(:gml).and_return(nil)
      expect {
        get :show, id: @tag.to_param, format: 'gml'
        puts response.body.inspect
        response.should be_success
      }.to raise_error(MissingDataError)
    end
  end

  describe "GET #validate" do
    it "should not route, we want you to use POST only now" do
      { get: "/validate" }.should_not be_routable
    end
  end

  describe "POST #validate" do
    it "should route" do
      { post: "/validate" }.should route_to("tags#validate")
    end

    it "should work given an existing tag_id (via tag[id])" do
      @tag = FactoryBot.create(:tag)
      post :validate, tag: {id: @tag.id}
      response.should be_success
      response.body.should match(/Validating Tag ##{@tag.id}/)
    end

    it "should present form for submitting GML if no tag data" do
      post :validate
      response.should be_success
      response.body.should match(/GML Syntax Validator/)
    end

    it "should work with raw :tag data" do
      post :validate, tag: {gml: "<gml>...</gml>"}
      response.should be_success
      response.body.should match(/Validating Your Uploaded GML.../)
    end

    it "should return XML" do
      @tag = FactoryBot.create(:tag)
      post :validate, id: @tag.id, format: 'xml'
      response.should be_success
      response.body.should match('<warnings>')
    end

    it "should return JSON" do
      @tag = FactoryBot.create(:tag)
      post :validate, id: @tag.id, format: 'json'
      response.should be_success
      response.body.should match('"warnings":')
    end

    it "should return text" do
      @tag = FactoryBot.create(:tag)
      post :validate, id: @tag.id, format: 'text'
      response.should be_success
      response.body.should match('warnings=')
    end

    it "should return text via XMLHttpRequest" do
      @tag = FactoryBot.create(:tag)
      request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
      post :validate, id: @tag.id
      response.should be_success
      response.body.should match('warnings=')
    end
  end

  describe "GET #latest" do
    it ".html redirects to the latest" do
      tag = FactoryBot.create(:tag)
      get :latest
      assigns(:tag).should == tag
      path = tag_path(tag)
      response.should redirect_to(path)
    end

    it ".json returns latest" do
      tag = FactoryBot.create(:tag)
      get :latest, format: 'json'
      assigns(:tag).should == tag
      response.should be_success
      JSON.parse(response.body)['id'].should == tag.id
    end
  end

  describe "GET #random" do
    it "works" do
      FactoryBot.create(:tag)
      get :random
      assigns(:tag).should_not be_nil
      response.should be_redirect
    end
  end
end
