module RollupData
  module Humanization

    HUMAN_QUERY_NAMES = {
      'photos.all' => 'Photos',
      'albums.all' => 'Albums',
      #Photo sources (Photos.source)
      'photos.source.flickr' => 'Flickr',
      'photos.source.facebook' => 'Facebook',
      'photos.source.shutterfly' => 'Shutterfly',
      'photos.source.photobucket' => 'Photobucket',
      'photos.source.instagram' => 'Instagram',
      'photos.source.smugmug' => 'Smugmug',
      'photos.source.kodak' => 'Kodak Gallery',
      'photos.source.picasaweb' => 'Picasa Web',
      'photos.source.email' => 'E-Mail',
      'photos.source.zangzing' => 'ZangZing',
      'photos.source.fs.osx' => 'Agent Mac',
      'photos.source.fs.win' => 'Agent PC',
      'photos.source.iphoto.osx' => 'iPhoto Mac',
      'photos.source.picasa.osx' => 'Picasa Mac',
      'photos.source.picasa.win' => 'Picasa PC',
      'photos.source.simple.osx' => 'Simple Uploader Mac',
      'photos.source.simple.win' => 'Simple Uploader PC',
      'photos.source.simple' => 'Simple Uploader',
      #Likes
      'like.album.like' => 'Album like',
      'like.photo.like' => 'Photo like',
      'like.user.like' => 'User like',
      'like.album.unlike' => 'Album unlike',
      'like.photo.unlike' => 'Photo unlike',
      'like.user.unlike'=> 'User unlike',
      #Shares
      'photo.share.email' => 'via Email',
      'photo.share.facebook' => 'via Facebook',
      'photo.share.twitter' => 'via Twitter',
      'album.share.email' => 'via EMail',
      'album.share.facebook' => 'via Facebook',
      'album.share.twitter' => 'via Twitter',
    }

    def humanize_series_names!
      @chart_series.each { |serie| serie[:name] = human_query_name(serie[:name]) }
      #@chart_series = @chart_series.sort_by{|s| s[:name] }
    end

    def human_query_name(query_name)
      HUMAN_QUERY_NAMES[query_name.downcase] || ( @humanize_unknown_series ? query_name.gsub('.', ' ').humanize : query_name )
    end


  end
end