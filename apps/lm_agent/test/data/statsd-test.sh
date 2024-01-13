#!/bin/bash

while true
do
    sleep $((RANDOM % 5)) 


    emit_stat() {
        printf $1 $((RANDOM % $2)) > /dev/udp/127.0.0.1/8125
    }

    emit_stat "test_statsd_c:%d|c|@0.5|#tag_key:tag_value" 1000
    emit_stat "test_statsd_negative_c:-%d|c|@0.5|#tag_key:tag_value,second_tag_key,third_tag_key:third_tag_key_value" 1000
    
    emit_stat "test_statsd_m:%d|m|@0.75|#tag_key:tag_value" 1000
    
    emit_stat "test_statsd_ms:%d|ms" 1000
    
    emit_stat "test_statsd_g:%d|g|#tag_key:tag_value" 1000
    
    emit_stat "test_statsd_gdiff:+%d|g|#tag_key:tag_value" 1000
    emit_stat "test_statsd_gdiff:-%d|g|#tag_key:tag_value" 1000
    
    emit_stat "test_statsd_h:%d|h|#tag_key:tag_value" 1000
    
    emit_stat "test_statsd_s:user%d|s" 10
    
    emit_stat "test_statsd_d:user%d|d" 10
    emit_stat "test_statsd_d:user%d|d" 10
    emit_stat "test_statsd_d:user%d|d" 10
    emit_stat "test_statsd_d:user%d|d" 10
    emit_stat "test_statsd_d:user%d|d" 10
    
    emit_stat "gorets:1|c\nglork:320|ms\ngaugor:333|g\nuniques:765|s" 1000
done