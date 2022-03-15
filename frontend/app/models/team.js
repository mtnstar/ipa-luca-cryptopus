import Model, { attr, hasMany } from "@ember-data/model";

export default class Team extends Model {
  @attr("string") name;
  @attr("string") description;
  @attr("boolean") private;
  @attr("boolean") favourised;
  @attr("boolean") deletable;
  @attr("string") encryptionAlgorithm;
  @attr("number") passwordBytesize;
  @hasMany("folder") folders;
  @hasMany("teammember") teammembers;
}
