import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:toml/toml.dart';

import 'discord_api.dart';

/// Representation of a JSON map, defined specifically for commands, but can be used for anything
/// requiring the Map<String, dynamic> type.
typedef CommandMap = Map<String, dynamic>;

/// The starting point for Lirx, enabling the addition and management of application commands.
class Lirx {
  /// Token of the Bot the commands will be made for. Used to instantiate [apiClient].
  final String botToken;

  /// ID of the Application that the Bot account is a part of. Used to instantiate [apiClient].
  final BigInt applicationID;

  /// Client in charge of making REST requests to Discord's api.
  late final DiscordAPI apiClient;

  /// List of all the commands that have been loaded into Lirx through
  /// [Lirx.loadCommandMap()], [Lirx.loadCommandFile()], and [Lirx.loadCommandFiles()].
  ///
  /// Only used for bulk publishing, any other methods require the use of providing
  /// a single [CommandMap] as necessary.
  ///
  /// This is not updated under any instance of editing or deleting published commands, as the
  /// designed use case is for Lirx to be for one-shot management, rather than being constantly
  /// running.
  List<CommandMap> commandList = [];

  /// Instantiates the Lirx class.
  ///
  /// Also instantiates [apiClient], which can be then utilized from this Lirx instance, or
  /// created on it's own.
  ///
  /// [botToken] is the token used to authenticate requests sent to Discord, and should be the
  /// token for a Bot account. <br>
  /// [applicationID] is the application ID for the bot/application. <br>
  /// [discordURL] is the primary domain that will be used when sending requests to Discord.
  /// Defaults to "https://discord.com/api/". If this is changed, it must include the final "/". <br>
  /// [apiVersion] will be the version of Discord's API that will be used. Defaults to "v10".
  Lirx({required this.botToken, required this.applicationID, String? discordURL, String? apiVersion}) {
    if (discordURL == null && apiVersion == null) {
      apiClient = DiscordAPI(authToken: botToken, applicationID: applicationID);
    } else if (discordURL != null && apiVersion == null) {
      apiClient = DiscordAPI(authToken: botToken, applicationID: applicationID, discordURL: discordURL);
    } else if (discordURL == null && apiVersion != null) {
      apiClient = DiscordAPI(authToken: botToken, applicationID: applicationID, apiVersion: apiVersion);
    } else {
      apiClient = DiscordAPI(
          authToken: botToken,
          applicationID: applicationID,
          discordURL: discordURL!,
          apiVersion: apiVersion!);
    }
  }

  /// Helper method converting a TOML file to a [CommandMap].
  Future<CommandMap> tomlToMap(String tomlPath) async {
    var document = await TomlDocument.load(tomlPath);
    return document.toMap();
  }

  /// Adds a [CommandMap] to [commandList] and returns the map passed.
  CommandMap loadCommandMap(CommandMap commandMap) {
    commandList.add(commandMap);
    return commandMap;
  }

  /// Loads a TOML file representing a [CommandMap] found at [tomlPath].
  ///
  /// The path provided will depend on the root directory from which the program is ran.
  /// Returns the parsed [CommandMap] after adding it to the [commandList].
  Future<CommandMap> loadCommandFile(String tomlPath) async {
    return loadCommandMap(await tomlToMap(tomlPath));
  }

  /// Loads multiple TOML files representing [CommandMap]s from [pathList].
  ///
  /// The paths provided will depend on the root directory from which the program is ran.
  /// Returns the created [commandList] after all files have been loaded.
  Future<List<CommandMap>> loadCommandFiles(List<String> pathList) async {
    for (String path in pathList) {
      await loadCommandFile(path);
    }

    return commandList;
  }

  /// Publish a single [command] to discord either globally or to a [guildID].
  ///
  /// Returns with the representation of the command after being published to discord, which includes
  /// information such as localizations and the command id. If there is an error, the response will
  /// be the body explaining why the error occurred.
  Future<CommandMap> publishCommand(CommandMap command, {BigInt? guildID}) async {
    http.Response response = (guildID == null)
        ? await apiClient.createApplicationCommand(command)
        : await apiClient.createApplicationCommand(command, guildID: guildID);

    return jsonDecode(response.body);
  }

  /// Perform a bulk publish of all commands either globally or to a [guildID].
  ///
  /// This is performed as Discord's bulk overwrite, so all application commands will be overwritten
  /// by the commands in [commandList]. New commands will count towards the daily create limits, existing
  /// ones will not.
  ///
  /// Commands listed in [commandList] should follow the [CommandMap] structure. <br>
  /// Pass an empty list to [commandList] to clear all published commands either globally or in [guildID].
  /// If [commandList] is not passed, the generated [Lirx.commandList] will be used.
  Future<List<dynamic>> bulkPublishCommands({List<dynamic>? commandList, BigInt? guildID}) async {
    commandList ??= this.commandList;
    http.Response response = (guildID == null)
        ? await apiClient.bulkOverwriteApplicationCommands(commandList)
        : await apiClient.bulkOverwriteApplicationCommands(commandList, guildID: guildID);

    return jsonDecode(response.body);
  }

  /// Edit a published command identified by [commandID] either globally or in [guildID].
  ///
  /// Fields provided in [command] will override the contents of the original fields in the
  /// published command. Accepted fields to be passed are found here:
  /// https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command-json-params
  Future<CommandMap> editCommand(CommandMap command, {required BigInt commandID, BigInt? guildID}) async {
    http.Response response = (guildID == null)
        ? await apiClient.editApplicationCommand(command, commandID: commandID)
        : await apiClient.editApplicationCommand(command, commandID: commandID, guildID: guildID);

    return jsonDecode(response.body);
  }

  /// Delete a published command identified by [commandID] either globally or in [guildID].
  Future<bool> deleteCommand(BigInt commandID, {BigInt? guildID}) async {
    http.Response response = (guildID == null)
        ? await apiClient.deleteApplicationCommand(commandID: commandID)
        : await apiClient.deleteApplicationCommand(commandID: commandID, guildID: guildID);

    return response.statusCode == 204;
  }

  /// Get a published command identified by [commandID] either globally or in [guildID].
  Future<CommandMap> getCommand(BigInt commandID, {BigInt? guildID}) async {
    http.Response response = (guildID == null)
        ? await apiClient.getApplicationCommand(commandID: commandID)
        : await apiClient.getApplicationCommand(commandID: commandID, guildID: guildID);

    return jsonDecode(response.body);
  }

  /// Get all published commands either globally or in a [guildID], along with optionally [withLocalizations].
  ///
  /// When [withLocalizations] is true, the full localization dictionaries stored by discord
  /// will be returned. The expected list will be empty if there are no global commands,
  /// and if there are they will follow the [CommandMap] structure.
  Future<List<dynamic>> bulkGetCommands({BigInt? guildID, bool withLocalizations = false}) async {
    http.Response response = (guildID == null)
        ? await apiClient.getAllApplicationCommands(withLocalizations: withLocalizations)
        : await apiClient.getAllApplicationCommands(guildID: guildID, withLocalizations: withLocalizations);

    return jsonDecode(response.body);
  }

  /// Get the permissions for a command identified by [commandID] in [guildID].
  Future<CommandMap> getCommandPermissions(BigInt commandID, {required BigInt guildID}) async {
    http.Response response =
        await apiClient.getApplicationCommandPermissions(commandID: commandID, guildID: guildID);

    return jsonDecode(response.body);
  }

  /// Get the permissions for all commands in [guildID].
  Future<CommandMap> bulkGetCommandPermissions(BigInt guildID) async {
    http.Response response = await apiClient.getAllApplicationCommandPermissions(guildID: guildID);

    return jsonDecode(response.body);
  }

  /// Edit the [permissions] for the command [commandID] in [guildID].
  ///
  /// This endpoint requires a Bearer token, and will not work with a Bot token.
  /// Permissions must follow the application command permissions format.
  ///
  /// More info found here:
  /// https://discord.com/developers/docs/interactions/application-commands#permissions
  Future<CommandMap> editCommandPermissions(List<dynamic> permissions,
      {required BigInt commandID, required BigInt guildID, required String bearerToken}) async {
    http.Response response = await apiClient.editApplicationCommandPermissions(permissions,
        commandID: commandID, guildID: guildID, bearerToken: bearerToken);

    return jsonDecode(response.body);
  }
}
