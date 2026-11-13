local Art={images={},quads={}}
function Art.readData(style)
 local info=assert(require('assistant_sprites')[style]);local path='assistant_assets/sprites/'..info.file
 if love.filesystem.getInfo(path) then return love.image.newImageData(path) end
 local f=assert(io.open(require('assistant').assetRoot()..'/sprites/'..info.file,'rb'));local bytes=f:read('*a');f:close();return love.image.newImageData(love.filesystem.newFileData(bytes,info.file))
end
function Art.drawSprite(style,frame,x,bottom,height,flip)
 local info=assert(require('assistant_sprites')[style]);local image=Art.images[style]
 if not image then local ok,data=pcall(Art.readData,style);if not ok then require('assistant').artError=tostring(data);love.graphics.setColor(.3,.7,.6);love.graphics.circle('line',x,bottom-height*.5,24);return end;image=love.graphics.newImage(data);image:setFilter('linear','linear');Art.images[style]=image;Art.quads[style]={} end
 frame=math.max(1,math.min(info.count,frame or 1));local quad=Art.quads[style][frame]
 if not quad then quad=love.graphics.newQuad((frame-1)%info.columns*info.w,math.floor((frame-1)/info.columns)*info.h,info.w,info.h,image:getDimensions());Art.quads[style][frame]=quad end
 local scale=height/(info.referenceHeight or info.h);love.graphics.setColor(1,1,1);love.graphics.draw(image,quad,x,bottom-info.h*scale,0,flip and -scale or scale,scale,info.w*.5,0)
end
function Art.draw(s,o)
 local A=require('assistant');local style,frame,flip=A.pose(s,o,false);local info=require('assistant_sprites')[style];local height=math.min(o.h-34,(o.w-16)*(info.referenceHeight or info.h)/info.w)
 Art.drawSprite(style,frame,o.w*.5,o.h-2,height,flip)
 local bound=require('assistant_frame_bounds')[style][frame];local scale=height/(info.referenceHeight or info.h);local badgeY=math.max(1,o.h-2-(info.h-bound.y)*scale-28)
 love.graphics.setColor(.035,.08,.1,.92);love.graphics.rectangle('fill',(o.w-142)*.5,badgeY,142,24,8);love.graphics.setColor(.72,.94,.87);Art.font=Art.font or love.graphics.newFont(12);love.graphics.setFont(Art.font);love.graphics.printf('Jenny / click to ask',(o.w-142)*.5,badgeY+5,142,'center')
end
return Art
