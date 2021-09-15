# <img src="DigitalOust/Images.xcassets/AppIcon.appiconset/icon_64.png" width=24> DigitalOust

This is gonna be a short README, I'm writing it years after creating this (unfinished) project.

EDIT: it was not a short readme

## Preamble

Once upon a time I had a magnificent MacBook Pro mid-2009 that had a bit more to drink than it could handle. After dipping it in rice, as was customary in the 2000s, everything was working alright, except the sound.

I had the dreaded [red light](https://discussions.apple.com/thread/3694502) [coming out](https://fr.ifixit.com/R%C3%A9ponses/Afficher/59477/My+headphone+jack+glows+with+a+red+light) [of the jack input](https://superuser.com/questions/37777/macbook-pro-sound-doesnt-work-and-theres-a-red-light-coming-out-of-my-headph). Oh, what a dreadful destiny for this beautiful piece of sentient aluminium !

Thinking I could Solve All Things™, I decided this would be no more than a week's work.

## Let there (not) be light

Mind you, I did find a way to fix it ! You seed, the `AppleHDA` kernel extensions contains (contained?) a list of supported sound cards and their input/output list in `Platforms.xml.zlib`. After some tinkering I was able to:

- uncompress this file
- find the list of outputs/inputs related to my sound card, identified by IOKit layout,
- remove the SPDIF output
- recompress
- resign the kext
- et voilà !

## Fixing the world

I kid you not, it did work! I could enjoy both speakers or headphones and since I didn't use any SPDIF devices at the time there was absolutely no downsides!

I made this small utility to make this process a breeze, hoping to help anybody encountering this issue. Oh boy did I have big plans! Me, a young developer of barely 22 years of age? Helping unknown friends of the Internet to fix their computer?

## Loosing hope

Alas Apple decided to foil my plans and released macOS El Capitan, adding a lot of new security measures, namely kext signing and rootless mode. I tried to continue working on this a bit, but to be honest by the time I found a way to automate the process again a new security measure popped and it as back to the drawing board.

It could still be made to work, especially if we're targeting older versions of macOS for those specific MacBooks, but my dreams have been crushed to many times.

## Passing the torch

I will leave you with this project, feel free to get inspired and finally release the ultimate tool to fix the read ring of death (well, no audio).

Some pointers, if memory serves well: 

- the process described earlier should still be fairly similar
- macOS doesn't include kexts anymore, but a kextcache. Tools to uncompress those do exist, I don't know if it would be easy to integrate into an app
- macOS doesn't like when we replace its kexts anymore, but you *should* be able to copy/extract the original kext, edit its layout file, resign, and add it *into* the app (in `APP_ROOT/Contents/Library/Extensions/10.9/AppleHDA-udpated.kext`) then figure out a way to make it load
- I don't think there is an easy way to tell macOS to use the newly generated kext instead of the original one, but I think making it more specific for your hardware should work (kind of like CSS, the more specific it relates to the device macOS is trying to drive, the more likely that driver will be used)

If you do decide to go on this journey, do drop me a message or a PR, I'll find a way to help you if need be :)

Goodbye stranger, and think you for reading this far.
