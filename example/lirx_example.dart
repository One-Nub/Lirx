import 'package:lirx/lirx.dart';

void main() async {
  Lirx lirx = Lirx(
      botToken: "TOKEN",
      applicationID: BigInt.from(123));

  await lirx.loadCommandFiles(["example/commands/command.toml", "example/commands/subcommands.toml"]);

  var bulkResult = await lirx.bulkPublishCommands();
  print(bulkResult);
}
