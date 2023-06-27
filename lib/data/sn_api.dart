import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacker_news/data/models/item.dart';
import 'package:stacker_news/data/models/user.dart';

enum PostType {
  top,
  bitcoin,
  nostr,
  tech,
  meta,
  job,
}

final class Api {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://stacker.news/_next/data',
    ),
  );

  // Ignore 404 errors so we can update the build-id and re-fetch posts
  Api() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode == 404) {
            handler.resolve(Response(
              requestOptions: error.requestOptions,
              statusCode: 404,
            ));
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }
// START Posts / Items
  Future<List<Item>> fetchPosts(PostType postType) async {
    String stories = '';

    switch (postType) {
      case PostType.top:
        stories = 'top/posts/day.json?when=day';

        break;

      case PostType.bitcoin:
        stories = '~/bitcoin.json?sub=bitcoin';

        break;

      case PostType.nostr:
        stories = '~/nostr.json?sub=bitcoin';

        break;

      case PostType.tech:
        stories = '~/tech.json?sub=tech';

      case PostType.meta:
        stories = '~/meta.json?sub=meta';

      case PostType.job:
        stories = '~/jobs.json?sub=jobs';

        break;

      default:
        break;
    }

    String? currCommit = await _getCurrBuildId();

    final response = await dio.get('/$currCommit/$stories');

    if (response.statusCode == 200) {
      return _parseItems(response.data);
    }

    if (response.statusCode == 404) {
      await _fetchAndSaveCurrBuildId();

      currCommit = await _getCurrBuildId();

      final retryResponse = await dio.get('/$currCommit/$stories');

      if (retryResponse.statusCode == 200) {
        return _parseItems(retryResponse.data);
      } else {
        throw Exception('Error fetching posts');
      }
    } else {
      throw Exception('Error parsing build id');
    }
  }

  List<Item> _parseItems(dynamic responseData) {
    final data = responseData['pageProps']['data'];
    final List items = (data['items'] ?? data['topItems'])['items'];

    return items.map((item) => Item.fromJson(item)).toList();
  }

  Future<void> _fetchAndSaveCurrBuildId() async {
    final response = await dio.get('https://stacker.news');

    if (response.statusCode != 200) {
      throw Exception('Error fetching build id');
    }

    final regex = RegExp(r'\/_next\/static\/(\w+)\/_buildManifest.js');
    final match = regex.firstMatch(response.data);

    final buildId = match?.group(1);
    if (buildId == null) {
      throw Exception('Error parsing build id');
    }

    await _saveBuildId(buildId);
  }

  Future<void> _saveBuildId(String newBuildId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('build-id', newBuildId);
  }

  Future<String?> _getCurrBuildId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('build-id');
  }

  Future<List<Item>> fetchMorePosts(PostType postType, int from, int to) async {
    throw UnimplementedError();
  }

  Future<Item> fetchItem(Item post) async {
    String? currCommit = await _getCurrBuildId();
    final response = await dio.get('/$currCommit/items/${post.id}.json');
    if (response.statusCode != 200) {
      throw Exception('Error fetching comments');
    }

    final data = response.data['pageProps']['data']['item'];

    return Item.fromJson(data);
  }

// END Posts / Items

// START Profile
  Future<User> fetchProfile(String userName) async {
    String? currCommit = await _getCurrBuildId();

    final response =
        await dio.get('/$currCommit/$userName.json?name=$userName');

    if (response.statusCode == 200) {
      return _parseProfile(response.data);
    }

    if (response.statusCode == 404) {
      await _fetchAndSaveCurrBuildId();

      currCommit = await _getCurrBuildId();

      final retryResponse =
          await dio.get('/$currCommit/$userName.json?name=$userName');

      if (retryResponse.statusCode == 200) {
        return _parseProfile(retryResponse.data);
      } else {
        throw Exception('Error fetching profile');
      }
    } else {
      throw Exception('Error parsing build id');
    }
  }

  User _parseProfile(dynamic responseData) {
    final userMap =
        responseData['pageProps']['data']['user'] as Map<String, dynamic>;

    return User.fromJson(userMap);
  }
// END Profile
}

class NetworkError extends Error {}
