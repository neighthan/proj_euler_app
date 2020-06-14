import 'package:floor/floor.dart';

@entity
class Code {
  @primaryKey
  final int id;
  final String language;
  final String code;

  Code(this.id, this.language, this.code);
}

@dao
abstract class CodeDao {
  @Query("SELECT * FROM Code WHERE id = :id LIMIT 1")
  Future<Code> getCode(int id);

  @Insert(onConflict: OnConflictStrategy.REPLACE)
  Future<void> insertOrUpdateCode(Code code);
}
