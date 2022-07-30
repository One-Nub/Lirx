# Lirx
Toml-based Discord [application command](https://discord.com/developers/docs/interactions/application-commands) management. No more, no less.

---

## Getting started

### Installing with CLI:
```bash
dart pub add lirx
```
Then simply import it in your code!
```dart
import 'package:lirx/lirx.dart';
```

---

## Usage

> **Be warned! Lirx does not validate the TOML representations to see if they are considered valid Discord commands. That is up to you to validate before publishing commands to Discord!**

### Sample Dart file.
```dart
import 'package:lirx/lirx.dart';

void main() async {
  Lirx lirx = Lirx(
      botToken: "TOKEN",
      applicationID: BigInt.from(123)); // Replace with your application ID.

  await lirx.loadCommandFiles(["example/commands/command.toml", "example/commands/subcommands.toml"]);

  var bulkResult = await lirx.bulkPublishCommands();
  print(bulkResult);
}
```
### Sample TOML file based upon Discord's application command example JSON.
```toml
name = "blep"
description = "Send a random adorable animal photo"
type = 1

[[options]]
    name = "animal"
    description = "The type of animal"
    type = 3
    required = true
    choices = [
        {name = "Dog", value = "animal_dog"},
        {name = "Cat", value = "animal_cat"},
        {name = "Penguin", value = "animal_penguin"}
    ]

[[options]]
    name = "only_smol"
    description = "Whether to show only baby animals"
    type = 5
    required = false
```

---

## *Why make this?*
I've made Lirx because I want a low level ability to create and manage Discord application commands without needing to worry about the magic done by most Discord libraries which abstract the low level functionality. This then lets the programmer focus on implementation, while the library handles the dirty work of creation and management of these application commands, but that leaves the raw control behind, which I desired.

By separating the functions of creating and managing application commands from the actual function implementation of said commands, it is far easier to precisely control these application commands individually, since now the command creation process is disconnected from the implementation.

Plus, that's not to say Lirx can't be hooked into processes where command functionality and command management are implemented together! Lirx simply is meant to contain command creation and management to it's own module so it can be used wherever necessary without worrying about where the functionality may be.

--- 
## _So is it good for me?_
Well, it depends! Do you want to control the creation, updating, and deletion of your application commands from a separate controller compared to other popular libraries/frameworks which have it all in one? And also, do you want to write out command representations in TOML? If so, then great! This is for you.

Given the low level nature of this library though, this is not very beginner friendly. It practically requires the Discord documentation to be open at all times when writing commands since there are no tooltips or autofills for TOML. 

Along with that, Lirx is just for creating commands - there is no built-in way to recieve or handle the interactions spawned by these commands after they are published. That's left up to you!

I personally plan on updating [Onyx](https://github.com/One-Nub/Onyx) to work along with this package, so that Onyx will handle interaction dispatching to implementation functions.
