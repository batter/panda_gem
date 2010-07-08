require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Panda::Encoding do
  before(:each) do
    Time.stub!(:now).and_return(mock("time", :iso8601 => "2009-11-04T17:54:11+00:00"))

    cloud_json = "{\"s3_videos_bucket\":\"my_bucket\",\"id\":\"my_cloud_id\"}" 
    stub_http_request(:get, /http:\/\/myapihost:85\/v2\/clouds\/my_cloud_id.json/).to_return(:body => cloud_json)

    Panda.configure do |c|
      c.access_key = "my_access_key"
      c.secret_key = "my_secret_key"
      c.api_host = "myapihost"
      c.cloud_id = 'my_cloud_id'
      c.api_port = 85
    end
    
  end
  
  
  it "should find by video_id" do
    encoding_json = "[{\"abc\":\"efg\",\"id\":456}]"
    stub_http_request(:get, /myapihost:85\/v2\/videos\/123\/encodings.json/).to_return(:body => encoding_json)
    Panda::Encoding.find_all_by_video_id("123").first.id.should == 456    
  end

  it "should create a encodings" do
    encoding_json = "{\"source_url\":\"http://a.b.com/file.mp4\",\"id\":\"456\"}"
    stub_http_request(:post, /http:\/\/myapihost:85\/v2\/encodings.json/).
      with(:source_url =>"http://a.b.com/file.mp4").
        to_return(:body => encoding_json)
    
    encoding = Panda::Encoding.new(:source_url => "http://a.b.com/file.mp4", :video_id => "123")
    encoding.create.should == true
    encoding.id.should == "456" 
  end
  
  it "should find by encoding_id" do
    encoding_json = "{\"abc\":\"efg\",\"id\":\"456\"}"
    stub_http_request(:get, /myapihost:85\/v2\/encodings\/456.json/).to_return(:body => encoding_json)
    encoding = Panda::Encoding.find("456")
    encoding.id.should == "456"
  end
    
  it "should find by the video through the association" do
    video_json = "{\"source_url\":\"http://a.b.com/file.mp4\",\"id\":\"123\"}"
    encoding_json = "{\"abc\":\"efg\",\"id\":\"456\", \"video_id\":\"123\"}"
    stub_http_request(:get, /myapihost:85\/v2\/encodings\/456.json/).to_return(:body => encoding_json)
    stub_http_request(:get, /myapihost:85\/v2\/videos\/123.json/).to_return(:body => video_json)
    encoding = Panda::Encoding.find("456")
    encoding.video.id.should == "123"
    encoding.id.should == "456"
  end
  
  it "should filter on find" do
    encoding_json = "[{\"source_url\":\"http://a.b.com/file.mp4\",\"id\":\"456\"}]"
    
    stub_http_request(:get, /http:\/\/myapihost:85\/v2\/encodings.json/).
      with(:profile_name => "mp4").
        to_return(:body => encoding_json)

    encodings = Panda::Encoding.all(:video_id => "123", :profile_name => "my_profile")
    encodings.first.id.should == "456"
  end
  
  it "should return the video_url" do    
    encoding = Panda::Encoding.new({:id => "456", :extname => ".ext"})
    encoding.url.should == "http://s3.amazonaws.com/my_bucket/456.ext"
  end
end
