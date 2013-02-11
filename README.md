MineDown is a lightweight GUI front-end watchdog for cgminer, it utilises both the cgminer API & the Twilio SMS API 
and (once configured) will send an SMS Text message to alert you of a problem with your miner. 
(please see below for install instructions).

Simply head on over to www.Twilio.com and sign up for a 'free' Twilio account and then run the 
MineDown GUI setup to configure the cgminer watchdog.

Any requests, ideas or suggestions then please get in touch!

That's it!

Enjoy!

Email: Mark@juicypi.com

If you find this software useful then please donate to:

BTC = 1AmYBJ9vzeTWJebrg8wkh8sRh7Rc2TvgyB

LTC = LhcW62pTvAudYSxsAfGRDwGSJEJj1dummG 

I plan to create an installer once any initial bugs have been reported & ironed out, I am relatively new to linux, 
so any help, input, feedback or constructive critisism of where I can improve my code would be glady accepted.

For now anyone wishing to try this I suggest you use the following in a terminal:
(copy and paste the following)

cd /usr/bin
sudo su
wget https://raw.github.com/Mark-Leck/MineDown/master/minedown
chmod +x minedown
minedown

Note: this has only been tested on Ubunto 12.10 and the cgminer-2.10.5-x86_64-built version of cgminer, 
but should work with any versions containing the api-example.php (this 'MUST' be located in the same folder as cgminer)


