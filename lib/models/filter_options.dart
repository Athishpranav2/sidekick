enum PostType {
  all('🔀 All'),
  anonymous('🕶️ Anonymous'),
  public('🧑‍🤝‍🧑 Public');

  const PostType(this.displayName);
  final String displayName;
}

enum CategoryFilter {
  all('All'),
  positive('🟢 Positive'),
  negative('🔴 Negative'),
  sensitive('⚠️ Sensitive'),
  others('❓ Others');

  const CategoryFilter(this.displayName);
  final String displayName;
}

enum SortOption {
  recent('🕒 Recent'),
  mostLiked('❤️ Most Liked'),
  mostCommented('💬 Most Commented');

  const SortOption(this.displayName);
  final String displayName;
}

class FilterState {
  final PostType postType;
  final CategoryFilter category;
  final SortOption sortBy;
  final bool showMyPostsOnly;

  const FilterState({
    this.postType = PostType.all,
    this.category = CategoryFilter.all,
    this.sortBy = SortOption.recent,
    this.showMyPostsOnly = false,
  });

  FilterState copyWith({
    PostType? postType,
    CategoryFilter? category,
    SortOption? sortBy,
    bool? showMyPostsOnly,
  }) {
    return FilterState(
      postType: postType ?? this.postType,
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      showMyPostsOnly: showMyPostsOnly ?? this.showMyPostsOnly,
    );
  }
}
