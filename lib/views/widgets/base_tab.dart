import 'package:flutter/material.dart';
import 'package:stacker_news/data/models/item.dart';
import 'package:stacker_news/data/sn_api.dart';
import 'package:stacker_news/utils.dart';
import 'package:stacker_news/views/widgets/post_item.dart';
import 'package:stacker_news/views/widgets/post_list_error.dart';

class BaseTab extends StatefulWidget {
  final PostType postType;
  final dynamic onMoreTap;

  const BaseTab({
    Key? key,
    required this.postType,
    this.onMoreTap,
  }) : super(key: key);

  @override
  State<BaseTab> createState() => _BaseTabState();
}

class _BaseTabState extends State<BaseTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<List<Item>> _fetchPosts() async =>
      await Api().fetchPosts(widget.postType);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder(
      future: _fetchPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          final err = snapshot.error.toString();
          Utils.showError(context, err);
          return PostListError(err);
        }

        final posts = snapshot.data as List<Item>;

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchPosts,
                child: posts.isEmpty
                    ? const Center(child: Text('No posts found'))
                    : ListView.separated(
                        itemBuilder: (context, index) {
                          if (index == posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          return PostItem(
                            posts[index],
                            idx: index + 1,
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(),
                        itemCount: posts.length,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('MORE'),
                  onPressed: () {
                    Utils.showWarning(context, 'Not implemented yet');
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
