**WORK IN PROGRESS!**

This has several things specfic to my setup that probably won't work for you. I plan to remove those things since I'm pushing this repo to GitHub now. I'm just busy with another (private) project.

Liquidity is important and I want to help. This image has common commands you'll need to run makerdao keepers.

My setup looks like: [p2p network] <-> [geth] <-> [parity] <-> [lots of keepers]

Parity is allowed to have outbound p2p connections, but inbound connections all go to geth. I found this kept parity more responsive to rpc commands.

The parity node (for now on kovan testnet) should have rpc open to the keepers, but NOT to the internet. This RPC will have unlocked funds and so MUST be protected!

I have switched to using consul connect for communicating between most of my containers, but I haven't done that here yet. consul will also make it simple to build reserved_peers lists

You'll need several accounts and they will need to be unlocked. I need to write more about how many you'll need and how to fund them and HOW TO BACK THEM UP!!!

I need to use vault here so we do secrets right. don't just put things in env vars once we are on mainnet!

Because of how I installed the various makerdao app's into their own environments, you'll need the makerdao-helper script to get them on the path. I don't love this pattern, but it works.

