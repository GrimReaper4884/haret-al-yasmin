from PIL import Image, ImageDraw, ImageFont, ImageFilter
B='assets/marketing/banners/raw'
logo=Image.open('assets/marketing/logo/logo_wide_1600x400.png').convert('RGBA')
font=ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf',58)
jobs=[('ep1_v0','ad_jasmine_gate'),('ep2_v0','ad_red_gate'),('ep8_v1','ad_two_gates'),('infinite_v0','ad_moon_wall')]
for src,name in jobs:
    im=Image.open(f'{B}/{src}.png').convert('RGB')
    w,h=im.size; cw=int(h*16/9)
    if cw<=w: im=im.crop(((w-cw)//2,0,(w-cw)//2+cw,h))
    else:
        ch=int(w*9/16); im=im.crop((0,(h-ch)//2,w,(h-ch)//2+ch))
    im=im.resize((1920,1080),Image.LANCZOS).convert('RGBA')
    # bottom shade so the logo reads
    shade=Image.new('L',(1920,1080),0); d=ImageDraw.Draw(shade)
    for y in range(560,1080):
        d.line([(0,y),(1920,y)],fill=int(200*((y-560)/520)**1.4))
    black=Image.new('RGBA',(1920,1080),(10,6,4,255))
    im=Image.composite(black,im,shade)
    lw=1150; lg=logo.resize((lw,int(lw*logo.height/logo.width)),Image.LANCZOS)
    im.alpha_composite(lg,((1920-lw)//2,1080-lg.height-120))
    txt='CO-OP TOWER DEFENSE  ·  1–4 PLAYERS'
    dr=ImageDraw.Draw(im)
    tw=dr.textlength(txt,font=font)
    dr.text(((1920-tw)/2,1080-110),txt,font=font,fill=(246,214,140,255),stroke_width=5,stroke_fill=(48,28,14,255))
    im.convert('RGB').save(f'assets/marketing/ads/{name}.jpg',quality=92)
    print(name)
# preview sheet
sheet=Image.new('RGB',(2*960,2*540))
for i,(_,n) in enumerate(jobs):
    sheet.paste(Image.open(f'assets/marketing/ads/{n}.jpg').resize((960,540)),((i%2)*960,(i//2)*540))
sheet.save(r'C:/Users/teyam/AppData/Local/Temp/claude/C--Users-teyam-Documents-HaretAlYasmin/81958217-e4ec-4546-ad4c-fb14387f013b/scratchpad/ads_sheet.jpg',quality=85)
