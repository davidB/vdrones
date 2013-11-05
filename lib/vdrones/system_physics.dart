part of vdrones;

class ColliderInfo {
  Entity e;
  // the collision groupId
  int group; //HACK quick to know the entity kind
}

class Collisions extends Component {
  static final CT = ComponentTypeManager.getTypeFor(Collisions);
  final colliders = new LinkedBag<ColliderInfo>();
}

class _EntityContactListener extends collisions.Resolver {
  ComponentMapper<Collisions> _collisionsMapper;

  _EntityContactListener(this._collisionsMapper);

  void notifyCollisionParticleSegment(Particles psA, int iA, Segment s, double tcoll){
    notifyCollision(psA.extradata, s.ps.extradata);
  }

  void notifyCollisionParticleParticle(Particles psA, int iA, Particles psB, int iB, double tcoll){
    notifyCollision(psA.extradata, psB.extradata);
  }

  void notifyCollision(ColliderInfo cA, ColliderInfo cB) {
    if (cA == null || cB == null) return;
    //if (contact.fixtureA.filter.groupIndex == contact.fixtureB.filter.groupIndex) return;
    _addCollisionOnce(cA, cB);
    _addCollisionOnce(cB, cA);
  }

  void _addCollisionOnce(ColliderInfo cA, ColliderInfo cB) {
    var collisionsA = _collisionsMapper.getSafe(cA.e);
    if (collisionsA != null) {
      var already = false;
      collisionsA.colliders.iterateAndUpdate((x){
        if (x.e == cB.e) already = true;
        return x;
      });
      if (!already){
        collisionsA.colliders.add(cB);
      }
    }
  }
}
