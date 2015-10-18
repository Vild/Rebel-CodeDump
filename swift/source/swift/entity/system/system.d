module swift.entity.system.system;

public import artemisd.aspect;
import artemisd.entity;
import artemisd.entitysystem;
import artemisd.utils.type;
import artemisd.utils.bag;

import std.parallelism;

abstract class System : EntitySystem {
public:
	this(Aspect aspect) {
		super(aspect);
	}

	mixin TypeDecl;

protected:
	void process(Entity e);
	
	final override void processEntities(Bag!Entity entities) {
		//foreach (i, ref elem; taskPool.parallel(entities.Data, entities.size()))
		foreach (i, ref elem; entities.Data[0..entities.size])
			process(elem);
	}
	
	final override bool checkProcessing() {
		return true;
	}

}

