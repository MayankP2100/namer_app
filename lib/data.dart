import 'package:hive/hive.dart';
part 'data.g.dart';

@HiveType(typeId: 0)
class WordPairData extends HiveObject {
  @HiveField(0)
  late String first;

  @HiveField(1)
  late String second;
}
