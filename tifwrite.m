function nothing = tifwrite( I,s )
num=size(I,3);
imwrite(I(:,:,1),s,'Compression','none');
for i=2:num
    imwrite(I(:,:,i),s,'WriteMode','append','Compression','none');
end
end

