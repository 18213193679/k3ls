beta�汾���޷���֤�����հ汾��Ⱦ�����ͬ��
�κ�BUG��ر�


׼��������
����ģ�ͣ���ģ�Ͳ��ʵ�sphere��ͼ���ɸ߹���ͼ������ͼ��
ʹ����Ϊ�߹���ͼʱ  spa<=>normal ����Ҫ������0.5���£���Ϊ������ͼʹ��ʱ����Ҫ������>=0.5��
ע��߹���ͼ����sphere���󲿷�pmx�Դ���sph������ֱ��ʹ�ã�������뻻�ɷ��ߣ����޸�Ϊ<��Ч>


ʹ�÷�����
��MME��Ϊģ�ͷ���controller�е�fx��ͬʱʹ��controller��pmx�ļ��ı������Ч����


Ԥ�ã�
���� roughness 0 ,metalness 0
�� roughness 1 ,metalness 0
���� roughness 0 ,metalness 1
�ǹ� roughness 1 ,metalness 1
Ƥ�� roughness 1 ,metalness 0,SSS 1,translucency 0.33

��һ����Ҫ����Ԥ�õ�����
��reflectance�����Ƴ����������ã�


���븽����
PSSM.x ���� ��Ӱ
HgSao.x  ����  �����ڱ���Ambientһ��ģ��GI��Ч��
Ambient.x ���� ������ xyzָ������������ɫ rxyzָ������ĵ�����ɫ Si ������ǿ�� Si�Ƽ�1-2�������޸ģ���Ҫ̫��
k3ls.x HDRЧ����SSSЧ������Ҫʹ��SSSЧ����������Gbuffer_init.pmx������Ϊ��һ����Ⱦ��pmx  Si����SSS_corrention Tr����HDRǿ��
Skybox.pmx ��պУ������滻hdr��ͼ���ɲ�Ҫ


ģ�͸�����ء�
�����滻ģ�͵�spa��ͼΪ������ͼ+�ڱ���ͼ:
ͨ��RGB������XYZ��A���ڱ���ͼY

ģ������controller�е�fx��ʼ��Ⱦ��
����fx��ʼЧ����ͬ������ͨ��ͬ����pmx�ļ��������Ч����
���� 	���ϣ�spa��ͼ�뷨����ͼ���
	���ϣ�����������
	���£�����Ч�����
	���£��Է��⣬�����������


���Ƴ�ExcellentShadow��
���Ƴ�Ambientǿ�ȶ���ģ��Toon��Emmisive��������

K3LS beta v0.9.2 MoePus 2016.10.30



Reference:
http://graphicrants.blogspot.jp/2013/08/specular-brdf-reference.html
http://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf
http://renderwonk.com/publications/s2010-shading-course/gotanda/course_note_practical_implementation_at_triace.pdf
http://www.iryoku.com/sssss/
http://iryoku.com/translucency/
https://zhuanlan.zhihu.com/p/20119162?refer=graphics
KlayGE(https://github.com/gongminmin/KlayGE)
Ray(https://github.com/ray-cast/ray-mmd)

Inspired by:
NCHLShader2
N2+CShader
MikuMikuEffect Reference


TODO:
���HDR����
SSDO ��
PSSM ��
Forward -> Deferred