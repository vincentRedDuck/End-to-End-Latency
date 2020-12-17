# End-to-End Latency
## Project Description
In the real environment, any device has its own clock timer. It means that the reference point of getting a timestamp is different. Because of that, estimating the end-to-end latency is inaccurate by getting the timestamp. In order to avoid that, the practical way is using the RTT to calculate the end-to-end latency. However, the path from source to destination or destination to source is probably different because of the routing mechanism. In addition, a router that is in the path is may congestion. Based on these, The RTT is may inaccurate. Therefore, this project implements a way that synchronizes all devices in the same network to make them have the same clock timer.

## Features
+ Measures the end-to-end delay.
+ Runs on a commodity P4-programable switch.
+ Synchronizes the different hosts which clock are different.

## Team Members

## Publications
