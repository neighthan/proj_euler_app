import "dart:convert";
import 'package:floor/floor.dart';

@entity
class Code {
  @primaryKey
  final int id;
  final String language;
  final String code;

  Code(this.id, this.language, this.code);

  Map<String, dynamic> toJson() {
    return {"id": id, "language": language, "code": code};
  }
}

@dao
abstract class CodeDao {
  @Query("SELECT * FROM Code WHERE id = :id LIMIT 1")
  Future<Code> getCode(int id);

  @Query("SELECT * FROM Code")
  Future<List<Code>> getAllCode();

  @Insert(onConflict: OnConflictStrategy.REPLACE)
  Future<void> insertOrUpdateCode(Code code);
}

Future<String> exportCodeTable(CodeDao codeDao) async {
  List<Code> allCode = await codeDao.getAllCode();
  return jsonEncode(allCode);
}
