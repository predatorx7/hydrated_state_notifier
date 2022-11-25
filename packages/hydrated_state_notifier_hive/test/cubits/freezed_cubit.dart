import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hydrated_state_notifier/hydrated_state_notifier.dart';

part 'freezed_cubit.freezed.dart';
part 'freezed_cubit.g.dart';

class FreezedCubit extends HydratedStateNotifier<Tree?> {
  FreezedCubit() : super(null);

  void setQuestion(Tree tree) => state = (tree);

  @override
  Map<String, dynamic>? toJson(Tree? state) => state?.toJson();

  @override
  Tree fromJson(Map<String, dynamic> json) => Tree.fromJson(json);
}

@freezed
class Question with _$Question {
  const factory Question({
    int? id,
    String? question,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}

@freezed
class Tree with _$Tree {
  const factory Tree({
    Question? question,
    Tree? left,
    Tree? right,
  }) = _QTree;

  factory Tree.fromJson(Map<String, dynamic> json) => _$TreeFromJson(json);
}
