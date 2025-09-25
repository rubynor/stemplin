module TurboStreams::ChangeVideoHelper
  def change_video(target, paths: [], permanent: false)
    paths = paths.to_json
    turbo_stream_action_tag :change_video, target: target, paths: paths, permanent: permanent
  end
end

Turbo::Streams::TagBuilder.prepend(TurboStreams::ChangeVideoHelper)
