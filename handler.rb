require 'json'
require 'contentful'
require 'securerandom'
require 'aws-sdk-s3'
require 'open-uri'

ERROR = {
	'INVALID_IMAGE_TYPE' => {type: "Invalid Image Type", message: "The entry or image path provided does not match the asset type 'image'"},
	'ENTRY_NOT_FOUND' => {type: "Entry Not Found", message: "The entry provided does not exist in the provided contentful space"}
}

def parse_error error_code, args={}
	return ERROR[error_code].merge({args: args})
end

# Takes a contentful entry id (Image only), returns the id with metadata on what is displayed in the image
#
def api event:, context:
  return process(event['queryStringParameters']['entry_id'], event['queryStringParameters']['reference_path'], event['queryStringParameters']['tag_path'])
end

def process entry_id, content_image_reference, tag_pth=nil, options={}
	#
	# check if the entry exists
	#
	entry = contentful_client.entry entry_id
	return resp(entry, [], parse_error('ENTRY_NOT_FOUND', {entry_id: entry_id, content_image_reference: content_image_reference})) if !entry

	#
	# check if the image is on the model
	#
	asset = entry.send(content_image_reference)
	return resp(entry, [], parse_error('INVALID_IMAGE_TYPE', {entry_id: entry_id, content_image_reference: content_image_reference})) if asset.image_url

	#
	# get the s3 object
	#
	obj = get_s3_obj asset.image_url

	#
	# detect the labels
	#
	tags = detect_labels obj

	#
	# return a response
	return resp(entry, tags, nil)
end

def get_s3_obj image_url
	obj_id = SecureRandom.hex(10)
	downloaded_image = open(image_url)
	s3 = Aws::S3::Resource.new(region: ENV['aws_region'])
	obj = s3.bucket(bucket).object(obj_id)
	obj.upload_file(downloaded_image)
	return obj
end

def detect_labels obj, confidence=70
	resp = rekognition_client.detect_labels({
	  image: {
	    s3_object: {
	      bucket: obj.bucket,
	      name: obj.key,
	    },
	  },
	  max_labels: 123,
	  min_confidence: confidence,
	})
	return resp.to_h[:labels].map(&:name)
end

def resp entry_id, tags, error, response_code=200
	return {
    statusCode: response_code,
    body: {
    	entry_id: entry_id,
    	tags: tags,
    	error: error
    }
  }
end

def contentful_client
	Contentful::Client.new(
	  access_token: ENV['contentful_access_token'],
	  space: ENV['contentful_space_id'],
	  dynamic_entries: :auto
	)
end

def rekognition_client
	Aws::Rekognition::Client.new(
	  region: ENV['aws_region'],
	 	access_key_id: ENV['aws_access_key_id'],
  	secret_access_key: ENV['aws_secret_access_key']
	)
end
