import 'dart:convert';

import 'package:http/http.dart' as http;

import 'lirx_base.dart';

/// Responsible for sending REST request to Discord's api endpoints.
class DiscordAPI {
  /// Library user agent as required by Discord.
  static const String _userAgent = "DiscordBot (https://github.com/One-Nub/lirx, 1.0.0)";

  /// Upstream base URL that Lirx will be forwarding requests to.
  final String discordURL;

  /// Version of the API that Lirx will be using.
  final String apiVersion;

  /// The Bot token that will be used to authorize.
  final String authToken;

  /// The ID of the application, used for making REST requests.
  final BigInt applicationID;

  /// Authorization string consisting of the [authToken] with the proper syntax for Discord.
  late final String _authorizationStr;

  /// Instantiates the DiscordAPI class.
  ///
  /// [authToken] is the token used to authenticate requests sent to Discord, and should be the
  /// token for a Bot account. <br>
  /// [applicationID] is the application ID for the bot/application. <br>
  /// [discordURL] is the primary domain that will be used when sending requests to Discord.
  /// Defaults to "https://discord.com/api/". If this is changed, it must include the final "/". <br>
  /// [apiVersion] will be the version of Discord's API that will be used. Defaults to "v10".
  DiscordAPI(
      {required this.authToken,
      required this.applicationID,
      this.discordURL = "https://discord.com/api/",
      this.apiVersion = "v10"}) {
    _authorizationStr = "Bot $authToken";
  }

  /// Build the final URI/URL that will be sent in the REST request.
  String _buildURI(String endpoint) {
    return "$discordURL$apiVersion/applications/$applicationID/$endpoint";
  }

  /// Build the headers that will be sent in the REST request.
  Map<String, String> _buildHeaders() {
    return {
      "Accept": "application/json",
      "Authorization": _authorizationStr,
      "User-Agent": _userAgent,
      "Content-Type": "application/json"
    };
  }

  /// Bulk retrieve all global or [guildID] specific application commands.
  ///
  /// Optionally retrieve all uploaded localizations by settings [withLocalizations] to true.
  Future<http.Response> getAllApplicationCommands({BigInt? guildID, bool withLocalizations = false}) async {
    String uriString = (guildID == null)
        ? _buildURI("commands?with_localizations=$withLocalizations")
        : _buildURI("guilds/$guildID/commands?with_localizations=$withLocalizations");

    var url = Uri.parse(uriString);
    return await http.get(url, headers: _buildHeaders());
  }

  /// Create an application [command] either globally or in a [guildID].
  Future<http.Response> createApplicationCommand(CommandMap command, {BigInt? guildID}) async {
    String uriString = (guildID == null) ? _buildURI("commands") : _buildURI("guilds/$guildID/commands");

    var url = Uri.parse(uriString);
    return await http.post(url, headers: _buildHeaders(), body: jsonEncode(command));
  }

  /// Get an application command based on it's [commandID], either globally or in a [guildID].
  Future<http.Response> getApplicationCommand({required BigInt commandID, BigInt? guildID}) async {
    var uriString = (guildID == null)
        ? _buildURI("commands/$commandID")
        : _buildURI("guilds/$guildID/command/$commandID");

    var uri = Uri.parse(uriString);
    return await http.get(uri, headers: _buildHeaders());
  }

  /// Edit an application command identified by [commandID] either globally or in [guildID].
  Future<http.Response> editApplicationCommand(CommandMap command,
      {required BigInt commandID, BigInt? guildID}) async {
    var uriString = (guildID == null)
        ? _buildURI("commands/$commandID")
        : _buildURI("guilds/$guildID/commands/$commandID");

    var uri = Uri.parse(uriString);
    return await http.patch(uri, headers: _buildHeaders(), body: jsonEncode(command));
  }

  /// Delete an application command identified by [commandID] either globally or in [guildID].
  Future<http.Response> deleteApplicationCommand({required BigInt commandID, BigInt? guildID}) async {
    var uriString = (guildID == null)
        ? _buildURI("commands/$commandID")
        : _buildURI("guilds/$guildID/commands/$commandID");

    var uri = Uri.parse(uriString);
    return await http.delete(uri, headers: _buildHeaders());
  }

  /// Bulk overwrite all published applications commands either globally or in [guildID]
  /// by the commands in [commandList].
  Future<http.Response> bulkOverwriteApplicationCommands(List<dynamic> commandList, {BigInt? guildID}) async {
    String uriString = (guildID == null) ? _buildURI("commands") : _buildURI("guilds/$guildID/commands");

    var url = Uri.parse(uriString);
    return await http.put(url, headers: _buildHeaders(), body: jsonEncode(commandList));
  }

  /// Get the permissions for all application commands in [guildID] owned by this application.
  Future<http.Response> getAllApplicationCommandPermissions({required BigInt guildID}) async {
    var url = Uri.parse(_buildURI("guilds/$guildID/commands/permissions"));
    return await http.get(url, headers: _buildHeaders());
  }

  /// Get the permissions for a command identified by [commandID] in [guildID].
  Future<http.Response> getApplicationCommandPermissions(
      {required BigInt commandID, required BigInt guildID}) async {
    var url = Uri.parse(_buildURI("guilds/$guildID/commands/$commandID/permissions"));
    return await http.get(url, headers: _buildHeaders());
  }

  /// Edit the [permissions] for the command [commandID] in [guildID].
  ///
  /// This endpoint requires a Bearer token, and will not work with a Bot token.
  /// Permissions must follow the application command permissions format.
  ///
  /// More info found here:
  /// https://discord.com/developers/docs/interactions/application-commands#permissions
  Future<http.Response> editApplicationCommandPermissions(List<dynamic> permissions,
      {required BigInt commandID, required BigInt guildID, required String bearerToken}) async {
    var headers = _buildHeaders();
    headers["Authorization"] = "Bearer $bearerToken";

    var url =
        Uri.parse(_buildURI("applications/$applicationID/guilds/$guildID/commands/$commandID/permissions"));
    return await http.put(url, headers: headers, body: jsonEncode(permissions));
  }
}
