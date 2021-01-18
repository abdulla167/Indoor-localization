package com.example.spring_boot_demo.controllers;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.example.spring_boot_demo.mapping.Tri;
import com.example.spring_boot_demo.model.*;
import static org.hamcrest.CoreMatchers.anyOf;

import java.io.IOException;
import java.util.*;

@RestController
public class EspController {
    private List<SseEmitter> emitters = new ArrayList<>();
    private List<SseEmitter> emitterspy = new ArrayList<>();
    private int Counter =0;
    private Dictionary<Integer, String> my_dict = new Hashtable<Integer, String>();
    
    
    public EspController() {
		my_dict.put(0, "0.54,0.235");
		my_dict.put(1, "0.54,0.5157");
		my_dict.put(2, "0.54,0.811");
		my_dict.put(3, "0.54,0.05");
		my_dict.put(4, "0.247,0.578");
		my_dict.put(5, "0.3,0.235");
		my_dict.put(6, "0.31,0.95");
	}
	//RandomForestClassifier randomForestClassifier;
    	//{{0,0,0},{},{}};
    
    @GetMapping("/model")
    public SseEmitter model() {
    	
    	SseEmitter sseEmitter = new SseEmitter(-1L);
        emitterspy.add(sseEmitter);
        sseEmitter.onCompletion(() -> {
            emitterspy.remove(sseEmitter);
        });
        return sseEmitter;
    }
    @GetMapping("/")
    public SseEmitter index() {
    	
        SseEmitter sseEmitter = new SseEmitter(-1L);
        emitters.add(sseEmitter);
        sseEmitter.onCompletion(() -> {
            emitters.remove(sseEmitter);
        });
        return sseEmitter;
    }

    @GetMapping("/hello")
    public String hello() {
        return "hello";
    }

    @PostMapping("/push")
    public void push(@RequestBody String data) {
    	//System.out.println(data);
    	System.out.println("data : " + data);
        String str[] = data.split(",", 0);
        //double input[]= {Double.parseDouble(str[0]) ,Double.parseDouble(str[1])};
    	int block = RandomForestClassifier.blockNo(str);
    	System.out.println("block no : " + block);
        for(SseEmitter emitter : emitters){
            try {
                emitter.send(SseEmitter.event().data(my_dict.get(block)));
            } catch (IOException e){
            }
        //}
    }}
    
 
}