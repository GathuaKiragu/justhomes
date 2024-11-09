class Video {
  final int id;
  final String url;
  final String user;
  final String caption;
  int likes;
  final int shares;
  var comments;

  Video({
    required this.id,
    required this.url,
    required this.user,
    required this.caption,
    required this.likes,
    required this.shares,
    required this.comments,
  });
}
