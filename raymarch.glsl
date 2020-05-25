#version 330
precision highp float;

#define MAX_MARCHING_STEPS 250.0
#define ANTIALIASING_SAMPLES 1.0
#define MIN_DIST 0.0
#define MAX_DIST 100.0
#define EPSILON 1e-4
#define LIGHT_DIRECTION normalize(vec3(-1.0, -1.0, -1.0))
#define LOD_MULTIPLIER 0.05
#define SHADOWS_ENABLED true
#define SHADOW_SHARPNESS 10000.0
#define SHADOW_DARKNESS 0.99
#define AMBIENT_OCCLUSION_STRENGTH 0.01
#define AMBIENT_OCCLUSION_COLOR_DELTA vec3(0.8, 0.8, 0.8)
#define DIFFUSE_ENABLED false
#define LIGHT_COLOUR vec3(1.0, 0.8902, 0.5647)
#define glow vec4(0.2, 0.8, 0.3, 0.5)
#define phi 1.61803399
#define FOV 45.0
#define FOG_BEGIN 10.0
#define FOG_END 15.0
#define FOG_COLOR vec3(0.3451, 0.3451, 0.3451, 1.0)

uniform vec2 iResolution;
uniform float iTime;
uniform vec3 cam;
uniform vec2 lookRot;

uniform float const_a;
uniform float const_b;
uniform float const_c;
uniform float const_d;
uniform float const_e;
uniform float const_f;
uniform float const_g;
uniform float const_h;
uniform float const_i;
uniform float const_j;
uniform int bool_a;

struct Material {
    vec3 diffuseColor;
    vec3 specularColor;
    float specularPow;
    float specularIntensity;
};

struct PointLight {
    vec3 pos;
    vec3 color;
    float intensity;
};

vec3 C = normalize(vec3(1.0, 0.0, 0.0));
mat3 rotate(float x, float y, float z) {
    mat3 xrot = mat3(
        vec3(1, 0, 0),
        vec3(0, cos(x), -sin(x)),
        vec3(0, sin(x), cos(x)) 
    );

    mat3 yrot = mat3(
        vec3(cos(y), 0, sin(y)), 
        vec3(0, 1, 0),
        vec3(-sin(y), 0, cos(y))
    );

    mat3 zrot = mat3(
        vec3(cos(z), -sin(z), 0),
        vec3(sin(z), cos(z), 0),
        vec3(0, 0, 1)
    );

    return xrot * yrot * zrot;
}

float boxSDF( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

vec4 icaTest(vec3 z) {
    vec3 icaTestC = vec3(const_a, const_b, const_c);
    vec3 col = vec3(1.0, 1.0, 1.0);
    
    // z = rotate(0.0, iTime, 0.2 * iTime) * z;
    // z = rotate(0.758, 0.0, 0.0) * z;
    // z = rotate(0.0, 2.0*sin(iTime), 0.0) * z;
    // z = rotate(-0.758, 0.0, 0.0) * z;

    int ITERATIONS = 15;
    float scale = const_j;//(0.2 * (sin(2.0*iTime) + 1.0));

    if (bool_a == 1) { // PREROTATE
        for (int i = 0; i < 5; ++i) {
            if (z.x-z.y<0.0) {z.yx=z.xy;}
            if (z.x-z.z<0.0) {z.xz=z.zx;}
            if (z.x+z.y<0.0) {z.xy=vec2(-z.y,z.x);}
            if (z.x+z.z<0.0) {z.xz=vec2(-z.z,z.x);}
        }
    }

    float colScale = 1.0;
    int n  = 0;
    for (; n < ITERATIONS && length(z) <= 100.0; ++n) {
        z = rotate(const_d, const_e, const_f) * z;

        // z.x = abs(z.x); z.y = abs(z.y); z.z = abs(z.z);
        int c = 0;
        if (z.x-z.y<0.0) {z.yx=z.xy; ++c;}
        if (z.x-z.z<0.0) {z.xz=z.zx; ++c;}
        if (z.x+z.y<0.0) {z.xy=vec2(-z.y,z.x); ++c;}
        if (z.x+z.z<0.0) {z.xz=vec2(-z.z,z.x); ++c;}


        vec3 newcol = vec3(0.0, 0.0, 0.0);
        if (c == 0) newcol.x = 1.0;
        if (c == 1) newcol.y = 1.0;
        if (c == 2) newcol.z = 1.0;
        if (c == 3) newcol.xy = vec2(1.0, 1.0);
        if (c == 4) newcol.yz = vec2(1.0, 1.0);

        col.x = min(col.x, abs(z.z));
        col.y = min(col.y, abs(z.y));
        col.z = min(col.z, length(z) / 2.0);
        z = rotate(const_g, const_h, const_i) * z;
        // z = rotate(0.1, 0.2, 0.3) * z;
        
        z.x = scale * z.x - icaTestC.x * (scale - 1.0);    
        z.y = scale * z.y - icaTestC.y * (scale - 1.0);
        z.z = scale * z.z;
        if(z.z>0.5*icaTestC.z*(scale-1.0)) z.z-=icaTestC.z * (scale-1.0);
    } 
    
    // col = max(col, vec3(0.01, 0.01, 0.01));
    // col.x = log(16 * col.x + 1.0) / log(17.0);
    // col.y = log(16 * col.y + 1.0) / log(17.0);
    // col.z = log(16 * col.z + 1.0) / log(17.0);
    return vec4(((length(z) - 1.0) * pow(scale, -float(n))),
        col.x, col.y, col.z);
}


#define _PHI_ (0.5*(1.0+sqrt(5.0)))
float stc[3]= float[](_PHI_,1.0,0.0);
#define IN3 (1.0/sqrt(14.0+6.0*sqrt(5.0)))
float n3[3]=float[](IN3*_PHI_,-IN3*(pow(_PHI_, 2.0)),-IN3*(2.0*_PHI_+1.0));
vec4 hollow (vec3 p){
    float scale = 2.0;
    float x = p.x;
    float y = p.y;
    float z = p.z;
    vec3 col = vec3(1.0, 1.0, 1.0);
    for(int i=0;i<5;i++){//5 pre-folds
        y=abs(y);
        z=abs(z);
        float t=x*n3[0]+y*n3[1]+z*n3[2];
        if(t<0){x-=2.0*t*n3[0];y-=2.0*t*n3[1];z-=2.0*t*n3[2];}
    }
    float r=x*x+y*y+z*z;
    float bailout = 10.0;
    float i = 0.0;
    for(i=0;i<10.0 && r<bailout;i+=1.0){
        vec3 new = rotate(const_d, const_e, const_f) * vec3(x,y,z);
        x = new.x; y = new.y; z = new.z;
        
        y=abs(y);
        if (bool_a == 1) z = abs(z);
        //z=abs(z);//I've removed this
        float t=x*n3[0]+y*n3[1]+z*n3[2];
        if(t<0){x-=2.0*t*n3[0];y-=2.0*t*n3[1];z-=2.0*t*n3[2];}
        

        col.x = min(col.x, abs(z));
        col.y = min(col.y, abs(y));
        col.z = min(col.z, abs(z));

        new = rotate(const_g, const_h, const_i) * vec3(x,y,z);
        x = new.x; y = new.y; z = new.z;

        x=scale*x-stc[0]*(scale-1.0);
        y=scale*y-stc[1]*(scale-1.0);
        z=scale*z-stc[2]*(scale-1.0);
     
      r=x*x+y*y+z*z;
   }
   return vec4((sqrt(x*x+y*y+z*z)-2.0)*pow(scale, -i), col.x, col.y, col.z);
}

vec4 pillars(vec3 z) {
    vec3 icaTestC = normalize(vec3(1.0, 1.0, 1.0));
    vec3 col = vec3(0.0, 0.0, 0.0);
    
    // z = rotate(0.0, iTime, 0.2 * iTime) * z;
    // z = rotate(0.758, 0.0, 0.0) * z;
    // z = rotate(0.0, 2.0*sin(iTime), 0.0) * z;
    // z = rotate(-0.758, 0.0, 0.0) * z;

    int ITERATIONS = 10;
    float scale = 2.0;//(0.2 * (sin(2.0*iTime) + 1.0));

    float colScale = 1.0;
    int n  = 0;
    for (; n < ITERATIONS && length(z) < 1.0; ++n) {
        z = rotate(3.14, 0.0, 0.0) * z;

        // z.x = abs(z.x); z.y = abs(z.y); z.z = abs(z.z);
        int c = 0;
        if (z.x-z.y<0.0) {z.yx=z.xy; ++c;}
        if (z.x-z.z<0.0) {z.xz=z.zx; ++c;}
        if (z.x+z.y<0.0) {z.xy=vec2(-z.y,z.x); ++c;}
        if (z.x+z.z<0.0) {z.xz=vec2(-z.z,z.x); ++c;}


        vec3 newcol = vec3(0.0, 0.0, 0.0);
        if (c == 0) newcol.x = 1.0;
        if (c == 1) newcol.y = 1.0;
        if (c == 2) newcol.z = 1.0;
        if (c == 3) newcol.xy = vec2(1.0, 1.0);
        if (c == 4) newcol.yz = vec2(1.0, 1.0);

        colScale *= 0.5;
        col = col + colScale * newcol;

        z = rotate(0.0, 0.0, 0.0) * z;
        
        z.x = scale * z.x - icaTestC.x * (scale - 1.0);    
        z.y = scale * z.y - icaTestC.y * (scale - 1.0);
        z.z = scale * z.z;
        if(z.z>0.5*icaTestC.z*(scale-1.0)) z.z-=icaTestC.z * (scale-1.0);
    }
    // vec3 box = vec3(0.5, 0.5, 0.5);
    return vec4((length(z)) * pow(scale, 1-float(n)),
        col.x, col.y, col.z);
}




float sphereSDF(vec3 point, float radius) {
    return length(point) - radius;
}

float coneSDF( vec3 p, vec2 c ) {
  float q = length(p.xy);
  return dot(c,vec2(q,p.z));
}

float torusSDF( vec3 p, vec2 t ) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

vec3 roseC = normalize(vec3(4.8, 2.0, 0.0));
vec4 roseCalc(vec3 z) {
    vec3 col = vec3(0.0, 0.0, 0.0);

    // z = rotate(0.758, 0.0, 0.0) * z;
    // z = rotate(0.0, 2.0*sin(iTime), 0.0) * z;
    // z = rotate(-0.758, 0.0, 0.0) * z;

    int ITERATIONS = 10;
    float scale = 1.1;//+ (0.2 * (sin(2.0*iTime) + 1.0));

    float colScale = 1.0;
    int n  = 0;
    for (; n < ITERATIONS && (z.x * z.x + z.y * z.y + z.z * z.z) < 100000.0; ++n) {
        // z = rotate(0.2*(1.0-sin(iTime)), 0.2*(1.0-sin(iTime)), 0.2*(1.0-sin(iTime))) * z;

        // z.x = abs(z.x); z.y = abs(z.y); z.z = abs(z.z);
        int c = 0;
        if (z.x-z.y<0.0) {z.yx=z.xy; ++c;}
        if (z.x-z.z<0.0) {z.xz=z.zx; ++c;}
        if (z.x+z.y<0.0) {z.xy=vec2(-z.y,z.x); ++c;}
        if (z.x+z.z<0.0) {z.xz=vec2(-z.z,z.x); ++c;}


        vec3 newcol = vec3(0.0, 0.0, 0.0);
        if (c == 0) newcol.x = 1.0;
        if (c == 1) newcol.y = 1.0;
        if (c == 2) newcol.z = 1.0;
        if (c == 3) newcol.xy = vec2(1.0, 1.0);
        if (c == 4) newcol.yz = vec2(1.0, 1.0);

        colScale *= 0.5;
        col = col + colScale * newcol;
        
        float t = 1.0;
        z = rotate((0.1 + 0.2 * sin(iTime))*(t + 0.2 * sin(iTime)), 0.2*(t + 0.2 * sin(iTime)), 0.2*(t + 0.2 * sin(iTime))) * z;
        // z = rotate(0.1*cos(iTime), 0.1* sin(iTime), 0.1*sin(iTime)) * z;
       
        z.x = scale * z.x - roseC.x * (scale - 1.0);    
        z.y = scale * z.y - roseC.y * (scale - 1.0);
        z.z = scale * z.z;
        if(z.z>0.5*roseC.z*(scale-1.0)) z.z-=roseC.z * (scale-1.0);
    }
    return vec4((length(z)- 2.0) * pow(scale, -float(n)),
        col.x, col.y, col.z);
}

float dot2(vec3 v) {return dot(v, v);}
float triangleSDF( vec3 p, vec3 a, vec3 b, vec3 c ) {
  vec3 ba = b - a; vec3 pa = p - a;
  vec3 cb = c - b; vec3 pb = p - b;
  vec3 ac = a - c; vec3 pc = p - c;
  vec3 nor = cross( ba, ac );

  return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(ac,nor),pc))<2.0)
     ?
     min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}




float sgn(float x) {
    if (x < 0.0) return -x;
    return x;
}

vec4 spongeCalc(vec3 z) {
    // z = rotate(0.758, 0.0, 0.0) * z;
    // z = rotate(0.0, 2.0*sin(iTime), 0.0) * z;
    // z = rotate(-0.758, 0.0, 0.0) * z;
    // z = rotate(iTime / 3.0, iTime / 3.0, iTime / 3.0) * z;
    int ITERATIONS = 5;
    float scale = 3.0;//+ (0.2 * (sin(2.0*iTime) + 1.0));
    vec3 col = vec3(1.0, 1.0, 1.0);
    int n  = 0;
    for (; n < ITERATIONS && (z.x * z.x + z.y * z.y + z.z * z.z) < 10000.0; ++n) {
        z = rotate(const_a, const_b, const_c) * z;
        z.x = abs(z.x); z.y = abs(z.y); z.z = abs(z.z);
        
        if (z.x-z.y<0.0) {z.yx=z.xy;}
        if (z.x-z.z<0.0) {z.xz=z.zx;}
        if (z.y-z.z<0.0) {z.zy=z.yz;}

        col.x = min(col.x, abs(z.z));
        col.y = min(col.y, abs(z.y));
        col.z = min(col.z, abs(z.z));

        z = rotate(const_d, const_e, const_f) * z;
        z.x = scale * z.x - 2.0;    
        z.y = scale * z.y - 2.0;
        z.z = scale * z.z;

        if(z.z>0.5*(scale-1.0)) z.z-=(scale-1.0);
    }
    vec3 box = vec3(1.0, 1.0, 1.0);
    return vec4(boxSDF(z, box) * pow(scale, -float(n)),
        col.x, col.y, col.z);
}

float fracCircleSDF(vec3 z) {
    z = rotate(iTime / 3.0, iTime / 3.0, iTime / 3.0) * z;

    int ITERATIONS = 10;
    float scale = 2.8;

    int n  = 0;
    for (; n < ITERATIONS && (z.x * z.x + z.y * z.y + z.z * z.z) < 100000.0; ++n) {
        z = rotate(0.2, -0.1, 0.3) * z;

        z.x = abs(z.x); z.y = abs(z.y); z.z = abs(z.z);
        
        if (z.x-z.y<0.0) {z.yx=z.xy;}
        if (z.x-z.z<0.0) {z.xz=z.zx;}
        if (z.y-z.z<0.0) {z.zy=z.yz;}

       
        z.x = scale * z.x - 2.0;    
        z.y = scale * z.y - 2.0;
        z.z = scale * z.z;
        // z = rotate(-0.2, 0.1, -0.3) *z;
        if(z.z>0.5*(scale-1.0)) z.z-=(scale-1.0);
    }
    return length(z) * pow(scale, -float(n));
}



float lerp(float a, float b, float t) {
    return a + t * (b - a);
}

float smin( float a, float b) {
    float k = 0.5;
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sceneSDF(vec3 point) {
    return icaTest(point).x;
    // return roseCalc(point).x;
    // return icaTest(point).x;
    // return smin(rhombusSDF(point), spongeSDF(point - vec3(sin(iTime), cos(iTime), sin(iTime))));
}

vec4 ray_march(vec3 pos, vec3 dir) {
    float iter = 0.0;
    float dist = MIN_DIST;
    float d = 10.0;

    float NEW_EPS = EPSILON;

    for (; iter < MAX_MARCHING_STEPS && dist < MAX_DIST; iter += 1.0) {
        d = sceneSDF(pos);
        dist += d;

        NEW_EPS = 2.0 * dist * tan(radians(FOV)/2.0) / iResolution.x;
        if (abs(d) < NEW_EPS) {
            iter += d / NEW_EPS;
            break;
        }

        pos += dir * d; 
    }
    return vec4(dist, iter, d, NEW_EPS);
}

float softshadow( in vec3 pos, in vec3 dir, float max_dist, float w ) {
    float s = 1.0;
    float iter = 0.0;
    for(float t=0.00; t<max_dist && iter < MAX_MARCHING_STEPS; iter += 1.0) {
        float h = sceneSDF(pos + dir*t);
        s = min(s, 0.5 + 0.5 * h / (w * t));
        if (s < 0.0) break;
        t += h;
    }
    //if (s > 0.0) return 1.0;
    s = max(s, 0.0);
    return s*s*(3.0 - 2.0 * s);
    //return 1.0; // smoothstep
}

float hardshadow( in vec3 pos, in vec3 dir, float max_dist) {
    float s = 1.0;
    float iter = 0.0;
    for(float t=0.00; t<max_dist && iter < MAX_MARCHING_STEPS; iter += 1.0) {
        float h = sceneSDF(pos + dir*t);
        if (h < EPSILON) return 0.3;
        t += h;
    }
    return 1.0;
}

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return rotate(-lookRot.x, -lookRot.y, 0.0) * normalize(vec3(xy, -z));
}

vec3 estimateNormal(vec3 p, float EPS) {
    float cur = sceneSDF(p);
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPS, p.y, p.z)) - cur,
        sceneSDF(vec3(p.x, p.y + EPS, p.z)) - cur,
        sceneSDF(vec3(p.x, p.y, p.z  + EPS)) - cur
    ));
}

// Phong and AO implementation taken from https://www.shadertoy.com/view/tscSRS

/*
----------------AO---------------
*/

//	This has faster falloff for AO intensity and fewer iterations
float AO(vec3 point, vec3 dir, float start) {
	float depth = start, dist;
    float step = 0.05, falloff = 1.0;
    float ao = 0.0;
    for(int i = 0; i < 5; ++i) {
        dist = sceneSDF(point + depth*dir);
        ao += falloff*clamp(depth - dist, 0.0, 1.0);
        depth += step;
        falloff *= 0.9;
    }
    
    return clamp(1.0 - 1.5*ao, 0.0, 1.0);
}

vec3 PhongContribForPointLight(vec3 point, vec3 normal, Material M, PointLight light) {
	vec3 lightDir = light.pos - point;
    float d = length(lightDir);
    lightDir = lightDir / d;
    float attenuation = 1./ (.02*d*d + d + 1.);

    float cosine = max(0., dot(normal, lightDir));
    //vec3 scaledNormal = normal * cosine;
    vec3 specular = vec3(0.);
    if(cosine > 0.00005) {	//remove condition for smooth transition at extreme angles
        vec3 reflected = reflect(-lightDir, normal);	//normalize(2.*scaledNormal - lightDir);
        specular = light.color * M.specularIntensity * M.specularColor * attenuation *
        				pow( max(0., dot(reflected, normalize(-point)) ), M.specularPow );
    }
    
    vec3 diffuse = light.color * M.diffuseColor * light.intensity * attenuation * cosine;
    return diffuse + specular;  
}
vec3 PhongIllumination(vec3 point, vec3 normal, vec3 surfaceColor) {
    Material M = Material(surfaceColor, vec3(1.0, 1.0, 1.0), 25.0, 1.7);
    
    vec3 ambient = surfaceColor * .2; // vec3(.79,.79,1.) // 0.05 orig
    vec3 color = ambient;

    
        // vec3 light1Pos = vec3(4.0 * sin(iTime),
        //                   2.0,
        //                   4.0 * cos(iTime));
    
    PointLight light = PointLight(vec3(4.0 * sin(iTime), 2.0, 4.0 * cos(iTime)), vec3(1., 1., 1.), 20.0);
    vec3 lightDir = light.pos - point;
    float lightDist = length(lightDir);
    lightDir /= lightDist;

    //! Soft Shadows cause problems with banding at high distances !
    //Change shadow technique here
    color += PhongContribForPointLight(point, normal, M, light) * hardshadow(point, lightDir, length(light.pos - point));
    

    // light = PointLight(vec3(4.0 * sin(iTime), 2.0, 4.0 * cos(iTime)), vec3(1., .7, .8), 4.);
    // lightDir = light.pos - point;
    // lightDist = length(lightDir);
    // lightDir /= lightDist;
    // //Change shadow technique here
    // color += PhongContribForPointLight(point, normal, M, light) * diffrShadow(point, lightDir, .01, lightDist);
    
    return color * AO(point, normal, 0.001);
}

void main() {
    if (gl_FragCoord.x >= iResolution.x) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    // vec3 cam = vec3(0.0, 0.0, 10.0);
    vec3 dir = rayDirection(FOV, iResolution.xy, gl_FragCoord.xy);
    vec4 info = ray_march(cam, dir);
    float dist = info.x;

    if (dist > MAX_DIST - EPSILON) {
        // Hit nothing
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);

        // smooth iteration count: http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-ii-lighting-and-coloring/
        float iteration = info.y;// + log(log(info.w))/log(1.3) - log(log(dot2(cam + dist * dir))) / log(1.3);
        gl_FragColor = mix(gl_FragColor, glow, 2.0 * iteration / MAX_MARCHING_STEPS);


        vec3 light1Pos = vec3(4.0 * sin(iTime),
                          2.0,
                          4.0 * cos(iTime));

        // float lightAmount = 50.0 * max(dot(dir, normalize(light1Pos - cam)) - 0.99, 0.0);
        float lightAmount = 1.0/dot(dir, normalize(light1Pos - cam));
        gl_FragColor += vec3(lightAmount, lightAmount, lightAmount);
        // gl_FragColor = mix(gl_FragColor, vec4(1.0, 1.0, 1.0, 1.0), lightAmount);
        // gl_FragColor = vec4(1.0, 0.0, 0.0, 0.0);
        return;
    } else {

        vec3 pos = cam + dist * dir;
        //vec3 col = vec3(0.0, 0.0, 0.0);
        vec3 orig_col = icaTest(cam + dist * dir).yzw;// vec3(0.3, 0.3, 0.3); //roseCalc(cam +dist * dir).yzw;//vec3(0.3);//vec3(0.7, 0.2, 0.3);

        
        vec3 normal = estimateNormal(pos, info.w / 2.0);

        vec3 K_a = vec3(0.2, 0.2, 0.2);
        vec3 K_d = vec3(0.7, 0.2, 0.2);
        vec3 K_s = vec3(1.0, 1.0, 1.0);
        float shininess = 10.0;
        
        vec3 col = PhongIllumination(pos, normal, orig_col); 
        // phongIphongIllumination(K_a, orig_col, K_s, shininess, pos, cam, normal).xyz;

        // float diffuse = max(1.0 - SHADOW_DARKNESS, clamp(dot(normal, -LIGHT_DIRECTION), 0.0, 1.0) * k);
        // col = orig_col * 4.0 * diffuse * LIGHT_COLOUR;
        
        

        // // // apply shadows
        // // k = max(k, 1.0 - SHADOW_DARKNESS);
        // // col += orig_col * LIGHT_COLOUR * k;

        // add ambient occlusion
        // float a = 1.0 / (1.0 + info.y * AMBIENT_OCCLUSION_STRENGTH);
        // col -= (1.0 - a) * AMBIENT_OCCLUSION_COLOR_DELTA;

        // make further spots darker
        float b = 1.0 / (1.0 + (info.z * 100.0) * AMBIENT_OCCLUSION_STRENGTH);
        col -= (1.0 - b) * AMBIENT_OCCLUSION_COLOR_DELTA;

        gl_FragColor = vec4(col.xyz, 1.0);//getColour(cam + info.x * dir);

        
        // gl_FragColor = (info.x / 10.0) * vec4(1.0, 1.0, 1.0, 1.0);
        // gl_FragColor = info.orbitCapture;
        // gl_FragColor.w = 1.0;//vec4(1.0, 1.0, 1.0, 1.0);
    }

    gl_FragColor = pow( gl_FragColor, vec4(1.0/2.2, 1.0/2.2, 1.0/2.2, 1.0) );
}
